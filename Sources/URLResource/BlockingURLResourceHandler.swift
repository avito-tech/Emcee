import Dispatch
import Foundation
import Logging
import Models
import SynchronousWaiter

public final class BlockingURLResourceHandler: URLResourceHandler {
    
    private let waiter: Waiter
    private var result: Either<URL, Error>?
    
    public enum HandlerError: Error {
        case timeout
        case failure(Error)
    }
    
    public init(
        waiter: Waiter = SynchronousWaiter()
    ) {
        self.waiter = waiter
    }
    
    public func wait(limit: TimeInterval, remoteUrl: URL) throws -> URL {
        return try waiter.waitForUnwrap(
            timeout: limit,
            valueProvider: {
                if let result = result {
                    return try result.dematerialize()
                } else {
                    return nil
                }
            },
            description: "Contents of '\(remoteUrl)'"
        )
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        Logger.verboseDebug("Obtained contents for '\(url)' at local url: '\(contentUrl)'")
        result = Either.success(contentUrl)
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        Logger.error("Failed to fetch contents for '\(url)': \(error)")
        result = Either.error(error)
    }
}
