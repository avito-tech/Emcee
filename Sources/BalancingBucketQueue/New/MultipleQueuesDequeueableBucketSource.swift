import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class MultipleQueuesDequeueableBucketSource: DequeueableBucketSource {
    private let dequeueableBucketSourceProvider: DequeueableBucketSourceProvider
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(
        dequeueableBucketSourceProvider: DequeueableBucketSourceProvider,
        multipleQueuesContainer: MultipleQueuesContainer
    ) {
        self.dequeueableBucketSourceProvider = dequeueableBucketSourceProvider
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueueHolders = multipleQueuesContainer.allRunningJobQueues().map {
                $0.bucketQueueHolder
            }
            
            for bucketQueueHolder in bucketQueueHolders {
                let dequeueableBucketSourceProvider = dequeueableBucketSourceProvider.createDequeueableBucketSource(
                    bucketQueueHolder: bucketQueueHolder
                )
                if let dequeuedBucket = dequeueableBucketSourceProvider.dequeueBucket(
                    workerCapabilities: workerCapabilities,
                    workerId: workerId
                ) {
                    return dequeuedBucket
                }
            }
            
            return nil
        }
    }
}
