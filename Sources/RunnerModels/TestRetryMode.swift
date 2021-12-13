import Foundation

public enum TestRetryMode: String, Codable, Hashable, CustomStringConvertible {
    /// Test will be retried on worker that has got to execute it as many times as required.
    case retryOnWorker
    
    /// In this mode, queue will utilize multiple workers to perform test retry.
    /// This retry mode is handful if workers may have different state which may result in additional test flakiness.
    /// Test will be executed on worker only once, regardless of its retry count. Then test result will be sent back to the queue, which may decide to retry it.
    /// In this case, test will retried by other worker which hasn't executed this test before.
    /// If there won't be such worker, retry will happen on any available worker.
    case retryThroughQueue
    
    public var description: String { rawValue }
}
