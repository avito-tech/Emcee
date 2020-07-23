import BucketQueue
import Foundation

public final class MultipleQueuesStuckBucketsReenqueuer: StuckBucketsReenqueuer {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        let jobQueues = multipleQueuesContainer.allRunningJobQueues()
        return jobQueues.flatMap { jobQueue -> [StuckBucket] in
            jobQueue.bucketQueue.reenqueueStuckBuckets()
        }
    }
}
