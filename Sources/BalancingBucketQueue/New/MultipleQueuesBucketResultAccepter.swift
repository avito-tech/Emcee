import BucketQueue
import Foundation
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
                    // jobQueue is not associated with bucketId, move over to the next jobQueue
                }
            }
            
            throw MultipleQueuesBucketResultAccepterError.noMatchingQueueFound(
                bucketId: bucketId,
                workerId: workerId
            )
        }
    }
}

public enum MultipleQueuesBucketResultAccepterError: Error, CustomStringConvertible {
    case noMatchingQueueFound(bucketId: BucketId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let bucketId, let workerId):
            return "Can't accept result for \(bucketId): no matching queue found for testing result from \(workerId)"
        }
    }
}
