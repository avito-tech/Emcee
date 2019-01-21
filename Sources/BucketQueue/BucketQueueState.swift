import Foundation
import Logging
import Models

public final class BucketQueueStateLogger {
    private let state: QueueState
    
    public init(state: QueueState) {
        self.state = state
    }
    
    public func logQueueSize() {
        Logger.info("Enqueued buckets: \(state.enqueuedBucketCount), dequeued buckets: \(state.dequeuedBucketCount)")
    }
}
