import Dispatch
import FileCache
import Foundation
import Logging
import Models

public final class URLResource {
    private let fileCache: FileCache
    private let urlSession: URLSession
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.URLResource.syncQueue")
    private let handlerQueue = DispatchQueue(label: "ru.avito.emcee.URLResource.handlerQueue")
    private let handlersWrapper: HandlersWrapper
    
    public enum `Error`: Swift.Error {
        case unknownError(response: URLResponse?)
    }
    
    public init(fileCache: FileCache, urlSession: URLSession) {
        self.fileCache = fileCache
        self.urlSession = urlSession
        self.handlersWrapper = HandlersWrapper(handlerQueue: handlerQueue)
    }
    
    public func fetchResource(url: URL, handler: URLResourceHandler) {
        let url = self.downloadUrl(resourceUrl: url)
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
    
    private func provideResourceImmediately_onSyncQueue(url: URL, handler: URLResourceHandler) {
        do {
            Logger.verboseDebug("Found already cached resource for url '\(url)'")
            let cacheUrl = try fileCache.urlForCachedContents(ofUrl: url)
            handlerQueue.async {
                handler.resourceUrl(contentUrl: cacheUrl, forUrl: url)
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
        return urlSession.downloadTask(with: request) { (localUrl: URL?, response: URLResponse?, error: Swift.Error?) in
            self.processDownloadResponse(url: url, error, response, localUrl)
        }
    }
    
    private func processDownloadResponse(url: URL, _ error: Swift.Error?, _ response: URLResponse?, _ localUrl: URL?) {
        syncQueue.async { [weak handlersWrapper, weak fileCache] in
            guard let handlersWrapper = handlersWrapper, let fileCache = fileCache else { return }
            
            if let error = error {
                handlersWrapper.failedToGetContents(forUrl: url, error: error)
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                handlersWrapper.failedToGetContents(forUrl: url, error: Error.unknownError(response: response))
            } else if let localUrl = localUrl {
                do {
                    try fileCache.store(contentsUrl: localUrl, ofUrl: url, operation: .move)
                    let cachedUrl = try fileCache.urlForCachedContents(ofUrl: url)
                    Logger.debug("Stored resource for '\(url)' in file cache")
                    handlersWrapper.resourceUrl(contentUrl: cachedUrl, forUrl: url)
                } catch {
                    handlersWrapper.failedToGetContents(forUrl: url, error: error)
                }
            } else {
                handlersWrapper.failedToGetContents(forUrl: url, error: Error.unknownError(response: response))
            }
            handlersWrapper.removeHandlers(url: url)
        }
    }
    
    private func downloadUrl(resourceUrl: URL) -> URL {
        var components = URLComponents(url: resourceUrl, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url ?? resourceUrl
    }
    
    public func evictResources(olderThan date: Date) throws -> [URL] {
        return try fileCache.cleanUpItems(olderThan: date)
    }
}
