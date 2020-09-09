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
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try multipleQueuesContainer.performWithExclusiveAccess {
            let appropriateJobQueues = multipleQueuesContainer.runningAndDeletedJobQueues()
            for jobQueue in appropriateJobQueues {
                do {
                    let result = try jobQueue.bucketQueue.accept(
                        bucketId: bucketId,
                        testingResult: testingResult,
                        workerId: workerId
                    )
                    jobQueue.resultsCollector.append(testingResult: result.testingResultToCollect)
                    return result
                } catch {
                    Logger.debug("Job \(jobQueue.job) is not associated with \(bucketId)")
                }
            }
            
            throw BalancingBucketQueueError.noMatchingQueueFound(
                bucketId: bucketId,
                workerId: workerId
            )
        }
    }
}
