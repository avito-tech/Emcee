import Foundation
import Models

public final class HandlersWrapper: URLResourceHandler {
    private var handlers = MapWithCollection<URL, URLResourceHandler>()
    private let handlerQueue: DispatchQueue
    
    public init(handlerQueue: DispatchQueue) {
        self.handlerQueue = handlerQueue
    }
    
    public func countOfHandlersAfterAppending(handler: URLResourceHandler, url: URL) -> Int {
        handlers.append(key: url, element: handler)
        return handlers[url].count
    }
    
    public func removeHandlers(url: URL) {
        handlers.removeValue(forKey: url)
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        forEachHandler(collection: handlers[url]) { handler in
            handler.resourceUrl(contentUrl: contentUrl, forUrl: url)
        }
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        forEachHandler(collection: handlers[url]) { handler in
            handler.failedToGetContents(forUrl: url, error: error)
        }
    }
    
    private func forEachHandler(collection: Array<URLResourceHandler>, work: @escaping (URLResourceHandler) -> Void) {
        handlerQueue.async {
            for handler in collection {
                work(handler)
            }
        }
    }
}
