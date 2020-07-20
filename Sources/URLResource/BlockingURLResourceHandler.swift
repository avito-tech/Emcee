import AtomicModels
import Dispatch
import Foundation
import Logging
import Models
import PathLib
import SynchronousWaiter
import Types

public final class BlockingURLResourceHandler: URLResourceHandler {
    
    private let waiter: Waiter
    private let result: AtomicValue<Either<AbsolutePath, Error>?> = AtomicValue(nil)

    public init(
        waiter: Waiter = SynchronousWaiter()
    ) {
        self.waiter = waiter
    }
    
    public func wait(limit: TimeInterval, remoteUrl: URL) throws -> AbsolutePath {
        return try waiter.waitForUnwrap(
            timeout: limit,
            valueProvider: {
                if let result = result.currentValue() {
                    return try result.dematerialize()
                } else {
                    return nil
                }
            },
            description: "Download contents of '\(remoteUrl)'"
        )
    }
    
    public func resource(path: AbsolutePath, forUrl url: URL) {
        Logger.verboseDebug("Obtained contents for \(url) at \(path)")
        result.set(Either.success(path))
    }
    
    public func failedToGetContents(forUrl url: URL, error: Error) {
        Logger.error("Failed to fetch contents for \(url): \(error)")
        result.set(Either.error(error))
    }
}
