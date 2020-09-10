import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class MultipleQueuesDequeueableBucketSource: DequeueableBucketSource {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(
        multipleQueuesContainer: MultipleQueuesContainer
    ) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueues = multipleQueuesContainer.allRunningJobQueues().map {
                $0.bucketQueue
            }
            
            for queue in bucketQueues {
                if let dequeuedBucket = queue.dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId) {
                    return dequeuedBucket
                }
            }
            
            return nil
        }
    }
}
