import BucketQueue
import Foundation
import Logging
import QueueModels

public final class MultipleQueuesBucketResultAccepter: BucketResultAccepter {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func accept(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try multipleQueuesContainer.performWithExclusiveAccess {
            if let appropriateJobQueue = multipleQueuesContainer
                .runningAndDeletedJobQueues()
                .first(where: { jobQueue in
                    jobQueue.bucketQueue.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) != nil
                }) {
                Logger.debug("Found corresponding job queue for \(requestId) \(workerId)")
                let result = try appropriateJobQueue.bucketQueue.accept(
                    testingResult: testingResult,
                    requestId: requestId,
                    workerId: workerId
                )
                appropriateJobQueue.resultsCollector.append(testingResult: result.testingResultToCollect)
                return result
            }
            
            throw BalancingBucketQueueError.noMatchingQueueFound(
                testingResult: testingResult,
                requestId: requestId,
                workerId: workerId
            )
        }
    }
}
