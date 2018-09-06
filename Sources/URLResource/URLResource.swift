import FileCache
import Foundation
import Logging

public final class URLResource {
    private let fileCache: FileCache
    private let urlSession: URLSession
    
    public enum `Error`: Swift.Error {
        case unknownError(response: URLResponse?)
    }
    
    public init(fileCache: FileCache, urlSession: URLSession) {
        self.fileCache = fileCache
        self.urlSession = urlSession
    }
    
    public func fetchResource(url: URL, handler: URLResourceHandler) {
        if fileCache.contains(itemForURL: url) {
            do {
                log("Found already cached resource for url '\(url)'")
                let cacheUrl = try fileCache.urlForCachedContents(ofUrl: url)
                handler.resourceUrl(contentUrl: cacheUrl, forUrl: url)
            } catch {
                handler.failedToGetContents(forUrl: url, error: error)
            }
        } else {
            log("Will fetch resource for url '\(url)'")
            let task = urlSession.downloadTask(with: url) { (localUrl: URL?, response: URLResponse?, error: Swift.Error?) in
                if let error = error {
                    handler.failedToGetContents(forUrl: url, error: error)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    handler.failedToGetContents(forUrl: url, error: Error.unknownError(response: response))
                } else if let localUrl = localUrl {
                    do {
                        try self.fileCache.store(contentsUrl: localUrl, ofUrl: url)
                        let cachedUrl = try self.fileCache.urlForCachedContents(ofUrl: url)
                        log("Stored resource for '\(url)' in file cache")
                        handler.resourceUrl(contentUrl: cachedUrl, forUrl: url)
                    } catch {
                        handler.failedToGetContents(forUrl: url, error: error)
                    }
                } else {
                    handler.failedToGetContents(forUrl: url, error: Error.unknownError(response: response))
                }
            }
            task.resume()
        }
    }
}
