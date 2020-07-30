import AtomicModels
import Dispatch
import Foundation
import Logging
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
        Logger.verboseDebug("Obtained contents for \(url) at \(path)")
        callbackWaiter.set(result: .success(path))
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        Logger.error("Failed to fetch contents for \(url): \(error)")
        callbackWaiter.set(result: .error(error))
    }
}
