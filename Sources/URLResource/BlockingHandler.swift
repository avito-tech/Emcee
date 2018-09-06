import Basic
import Dispatch
import Foundation
import Logging

public final class BlockingHandler: Handler {
    
    private let semaphore = DispatchSemaphore(value: 0)
    private var result: Result<URL, HandlerError> = Result.failure(HandlerError.timeout)
    
    public enum HandlerError: Error {
        case timeout
        case failure(Error)
    }
    
    public init() {}
    
    public func wait(limit: TimeInterval = 20.0) throws -> URL {
        _ = semaphore.wait(timeout: .now() + limit)
        return try result.dematerialize()
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        log("Obtained resource for '\(url)' at local url: '\(contentUrl)'")
        result = Result.success(contentUrl)
        semaphore.signal()
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        log("Failed to fetch resource for '\(url)': \(error)")
        result = Result.failure(HandlerError.failure(error))
        semaphore.signal()
    }
}
