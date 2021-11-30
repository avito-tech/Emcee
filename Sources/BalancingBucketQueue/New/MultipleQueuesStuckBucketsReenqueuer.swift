import BucketQueue
import BucketQueueModels
import Foundation

public final class MultipleQueuesStuckBucketsReenqueuer: StuckBucketsReenqueuer {
    private let multipleQueuesContainer: MultipleQueuesContainer
    private let stuckBucketsReenqueuerProvider: StuckBucketsReenqueuerProvider
    
    public init(
        multipleQueuesContainer: MultipleQueuesContainer,
        stuckBucketsReenqueuerProvider: StuckBucketsReenqueuerProvider
    ) {
        self.multipleQueuesContainer = multipleQueuesContainer
        self.stuckBucketsReenqueuerProvider = stuckBucketsReenqueuerProvider
    }
    
    public func reenqueueStuckBuckets() throws -> [StuckBucket] {
        let jobQueues = multipleQueuesContainer.allRunningJobQueues()
        return try jobQueues.flatMap { jobQueue -> [StuckBucket] in
            try stuckBucketsReenqueuerProvider.createStuckBucketsReenqueuer(
                bucketQueueHolder: jobQueue.bucketQueueHolder
            ).reenqueueStuckBuckets()
        }
    }
}
