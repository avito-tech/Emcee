import Dispatch
import FileCache
import Foundation
import Logging
import Models
import PathLib

public final class URLResource {
    private let fileCache: FileCache
    private let urlSession: URLSession
    private let syncQueue = DispatchQueue(label: "URLResource.syncQueue")
    private let handlerQueue = DispatchQueue(label: "URLResource.handlerQueue")
    private let handlersWrapper: HandlersWrapper
    
    public enum URLResourceError: Error, CustomStringConvertible {
        case invalidResponse(url: URL, response: URLResponse?)
        case noLocalUrl(url: URL, response: HTTPURLResponse)
        case noFileSizeAttribute(localUrl: URL)
        case unexpectedDownloadSize(url: URL, expected: Int64, actual: Int)
        
        public var description: String {
            switch self {
            case .invalidResponse(let url, let response):
                return "Invalid URL response for url \(url): \(response?.description ?? "NULL")"
            case .noLocalUrl(let url, let response):
                return "No local URL provided by URL session for url: \(url), response: \(response)"
            case .noFileSizeAttribute(let localUrl):
                return "Cannot get file size attribute for path: \(localUrl.path)"
            case .unexpectedDownloadSize(let url, let expected, let actual):
                return "Unexpected resulting file size for url \(url): expected size \(expected), actual: \(actual)"
            }
        }
    }
    
    public init(fileCache: FileCache, urlSession: URLSession) {
        self.fileCache = fileCache
        self.urlSession = urlSession
        self.handlersWrapper = HandlersWrapper(handlerQueue: handlerQueue)
    }
    
    public func fetchResource(url: URL, handler: URLResourceHandler) {
        let url = downloadUrl(resourceUrl: url)
        syncQueue.sync {
            if fileCache.contains(itemForURL: url) {
                provideResourceImmediately_onSyncQueue(url: url, handler: handler)
            } else {
                if handlersWrapper.countOfHandlersAfterAppending(handler: handler, url: url) == 1 {
                    startLoadingUrlResource(url: url)
                }
            }
        }
    }
    
    public func deleteResource(url: URL) throws {
        try fileCache.delete(itemForURL: url)
    }
    
    private func provideResourceImmediately_onSyncQueue(url: URL, handler: URLResourceHandler) {
        do {
            let path = try fileCache.pathForCachedContents(ofUrl: url)
            handlerQueue.async {
                handler.resource(path: path, forUrl: url)
            }
        } catch {
            handlerQueue.async {
                handler.failedToGetContents(forUrl: url, error: error)
            }
        }
    }
    
    private func startLoadingUrlResource(url: URL) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        Logger.debug("Will fetch resource '\(url)'")
        let task = createDownloadTask(request: request, url: url)
        task.resume()
    }
    
    private func createDownloadTask(request: URLRequest, url: URL) -> URLSessionDownloadTask {
        let initiateDownloadTimestamp = Date()
        return urlSession.downloadTask(with: request) { (localUrl: URL?, response: URLResponse?, error: Swift.Error?) in
            self.processDownloadResponse(url: url, error, response, localUrl, initiateDownloadTimestamp)
        }
    }
    
    private func processDownloadResponse(url: URL, _ error: Swift.Error?, _ response: URLResponse?, _ localUrl: URL?, _ initiateDownloadTimestamp: Date) {
        syncQueue.async { [weak handlersWrapper, weak fileCache] in
            guard let handlersWrapper = handlersWrapper, let fileCache = fileCache else { return }
            
            defer {
                handlersWrapper.removeHandlers(url: url)
            }
            
            let receiveResponseTimestamp = Date()
            
            if let error = error {
                return handlersWrapper.failedToGetContents(forUrl: url, error: error)
            }
            
            guard let nonOptionalResponse = response, let httpResponse = nonOptionalResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return handlersWrapper.failedToGetContents(forUrl: url, error: URLResourceError.invalidResponse(url: url, response: response))
            }
            
            guard let localUrl = localUrl else {
                return handlersWrapper.failedToGetContents(forUrl: url, error: URLResourceError.noLocalUrl(url: url, response: httpResponse))
            }
            
            do {
                let timeToDownload = receiveResponseTimestamp.timeIntervalSince(initiateDownloadTimestamp)
                
                try self.validateDownloadedFileAgainstResponse(
                    url: url,
                    localUrl: localUrl,
                    response: httpResponse,
                    timeToDownload: timeToDownload
                )
                
                try fileCache.store(contentsPath: AbsolutePath(localUrl), ofUrl: url, operation: .move)
                let path = try fileCache.pathForCachedContents(ofUrl: url)
                Logger.debug("Stored resource for '\(url)' in file cache")
                handlersWrapper.resource(path: path, forUrl: url)
            } catch {
                handlersWrapper.failedToGetContents(forUrl: url, error: error)
            }
        }
    }
    
    private func validateDownloadedFileAgainstResponse(
        url: URL,
        localUrl: URL,
        response: URLResponse,
        timeToDownload: TimeInterval
    ) throws {
        let attribute = try FileManager.default.attributesOfItem(atPath: localUrl.path)
        
        guard let sizeAttributeValue = attribute[.size], let downloadedSize = sizeAttributeValue as? NSNumber else {
            throw URLResourceError.noFileSizeAttribute(localUrl: localUrl)
        }
        
        let sizeInBytes = downloadedSize.intValue
        let speedInKBytesPerSecond = Int(Double(sizeInBytes) / 1024 / timeToDownload)
        Logger.verboseDebug("Downloaded resource for '\(url)' in \(Int(timeToDownload)) seconds, size: \(sizeInBytes) bytes, speed: \(speedInKBytesPerSecond) KB/s")
        
        if response.expectedContentLength > 0, response.expectedContentLength != sizeInBytes {
            throw URLResourceError.unexpectedDownloadSize(url: url, expected: response.expectedContentLength, actual: downloadedSize.intValue)
        }
    }
    
    private func downloadUrl(resourceUrl: URL) -> URL {
        var components = URLComponents(url: resourceUrl, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url ?? resourceUrl
    }
    
    public func evictResources(olderThan date: Date) throws -> [AbsolutePath] {
        return try fileCache.cleanUpItems(olderThan: date)
    }
    
    public func whileLocked<T>(work: () throws -> (T)) throws -> T {
        return try fileCache.whileLocked(work: work)
    }
}
