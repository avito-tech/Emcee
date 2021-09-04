import BucketQueue
import BucketQueueModels
import Foundation

public final class MultipleQueuesStuckBucketsReenqueuer: StuckBucketsReenqueuer {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func reenqueueStuckBuckets() throws -> [StuckBucket] {
        let jobQueues = multipleQueuesContainer.allRunningJobQueues()
        return try jobQueues.flatMap { jobQueue -> [StuckBucket] in
            try jobQueue.bucketQueue.reenqueueStuckBuckets()
        }
    }
}
