import AtomicModels
import Dispatch
import Foundation
import PathLib
import SynchronousWaiter
import Types

public final class BlockingURLResourceHandler: URLResourceHandler {
    
    private let callbackWaiter: CallbackWaiter<Either<AbsolutePath, Error>>
    private let waiter: Waiter = SynchronousWaiter()

    public init() {
        callbackWaiter = waiter.createCallbackWaiter()
    }
    
    public func wait(limit: TimeInterval, remoteUrl: URL) throws -> AbsolutePath {
        return try callbackWaiter.wait(timeout: limit, description: "Download contents of '\(remoteUrl)'").dematerialize()
    }
    
    public func resource(path: AbsolutePath, forUrl url: URL) {
        callbackWaiter.set(result: .success(path))
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        callbackWaiter.set(result: .error(error))
    }
}
