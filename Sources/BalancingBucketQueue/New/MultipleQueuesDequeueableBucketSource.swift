import BucketQueue
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class MultipleQueuesDequeueableBucketSource: DequeueableBucketSource {
    private let multipleQueuesContainer: MultipleQueuesContainer
    private let nothingToDequeueBehavior: NothingToDequeueBehavior
    
    public init(
        multipleQueuesContainer: MultipleQueuesContainer,
        nothingToDequeueBehavior: NothingToDequeueBehavior
    ) {
        self.multipleQueuesContainer = multipleQueuesContainer
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueues = multipleQueuesContainer.allRunningJobQueues().map {
                $0.bucketQueue
            }
            
            var dequeueResults = [DequeueResult]()
            for queue in bucketQueues {
                let dequeueResult = queue.dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
                switch dequeueResult {
                case .dequeuedBucket:
                    return dequeueResult
                case .workerIsNotRegistered:
                    return .workerIsNotRegistered
                case .queueIsEmpty, .checkAgainLater:
                    dequeueResults.append(dequeueResult)
                }
            }
            
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: dequeueResults)
        }
    }
}
