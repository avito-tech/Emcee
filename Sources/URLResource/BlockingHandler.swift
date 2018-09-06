import Basic
import Foundation

public final class BlockingHandler: Handler {
    
    private let condition = NSCondition()
    private var result: Result<URL, HandlerError> = Result.failure(HandlerError.timeout)
    
    public enum HandlerError: Error {
        case timeout
        case failure(Error)
    }
    
    public init() {}
    
    public func wait(until limit: Date = Date.distantFuture) throws -> URL {
        condition.wait(until: limit)
        return try result.dematerialize()
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        result = Result.failure(HandlerError.failure(error))
        condition.signal()
    }
    
    public func resourceUrl(contentUrl: URL, forUrl url: URL) {
        result = Result.success(contentUrl)
        condition.signal()
    }
}
