import BucketQueue
import Foundation
import QueueModels

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
    
    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueues = multipleQueuesContainer.allRunningJobQueues().map {
                $0.bucketQueue
            }
            
            if let previouslyDequeuedBucket = bucketQueues
                .compactMap({ $0.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) })
                .first {
                return .dequeuedBucket(previouslyDequeuedBucket)
            }
            
            var dequeueResults = [DequeueResult]()
            for queue in bucketQueues {
                let dequeueResult = queue.dequeueBucket(requestId: requestId, workerId: workerId)
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
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        multipleQueuesContainer.performWithExclusiveAccess {
            multipleQueuesContainer.allRunningJobQueues()
                .compactMap { $0.bucketQueue.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) }
                .first
        }
    }
}
