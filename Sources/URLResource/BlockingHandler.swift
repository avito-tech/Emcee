import Basic
import Foundation
import Logging

public final class BlockingHandler: Handler {
    
    private let condition = NSCondition()
    private var result: Result<URL, HandlerError> = Result.failure(HandlerError.timeout)
    
    public enum HandlerError: Error {
        case timeout
        case failure(Error)
    }
    
    public init() {}
    
    public func wait(until limit: Date = Date().addingTimeInterval(60)) throws -> URL {
        condition.wait(until: limit)
        return try result.dematerialize()
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        log("Failed to fetch resource for '\(url)': \(error)")
        result = Result.failure(HandlerError.failure(error))
        condition.signal()
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        log("Obtained  resource for '\(url)' at local url: '\(contentUrl)'")
        result = Result.success(contentUrl)
        condition.signal()
    }
}
