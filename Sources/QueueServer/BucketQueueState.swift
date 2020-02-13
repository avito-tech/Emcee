import Foundation
import Logging
import QueueModels

public final class BucketQueueStateLogger {
    private let runningQueueState: RunningQueueState
    
    public init(runningQueueState: RunningQueueState) {
        self.runningQueueState = runningQueueState
    }
    
    public func logQueueSize() {
        Logger.info("Enqueued buckets: \(runningQueueState.enqueuedBucketCount), dequeued buckets: \(runningQueueState.dequeuedBucketCount)")
    }
}
