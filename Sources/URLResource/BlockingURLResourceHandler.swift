import Dispatch
import Foundation
import Logging
import Models

public final class BlockingURLResourceHandler: URLResourceHandler {
    
    private let semaphore = DispatchSemaphore(value: 0)
    private var result: Either<URL, HandlerError> = Either.error(HandlerError.timeout)
    
    public enum HandlerError: Error {
        case timeout
        case failure(Error)
    }
    
    public init() {}
    
    public func wait(limit: TimeInterval = .infinity) throws -> URL {
        _ = semaphore.wait(timeout: .now() + limit)
        return try result.dematerialize()
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        Logger.verboseDebug("Obtained resource for '\(url)' at local url: '\(contentUrl)'")
        result = Either.success(contentUrl)
        semaphore.signal()
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        Logger.error("Failed to fetch resource for '\(url)': \(error)")
        result = Either.error(HandlerError.failure(error))
        semaphore.signal()
    }
}
