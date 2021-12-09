import BucketQueue
import Foundation
import QueueModels

public final class MultipleQueuesBucketResultAcceptor: BucketResultAcceptor {
    private let bucketResultAcceptorProvider: BucketResultAcceptorProvider
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(
        bucketResultAcceptorProvider: BucketResultAcceptorProvider,
        multipleQueuesContainer: MultipleQueuesContainer
    ) {
        self.bucketResultAcceptorProvider = bucketResultAcceptorProvider
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func accept(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try multipleQueuesContainer.performWithExclusiveAccess {
            let appropriateJobQueues = multipleQueuesContainer.runningAndDeletedJobQueues()
            for jobQueue in appropriateJobQueues {
                do {
                    let bucketResultAcceptor = bucketResultAcceptorProvider.createBucketResultAcceptor(
                        bucketQueueHolder: jobQueue.bucketQueueHolder
                    )
                    let result = try bucketResultAcceptor.accept(
                        bucketId: bucketId,
                        bucketResult: bucketResult,
                        workerId: workerId
                    )
                    jobQueue.resultsCollector.append(bucketResult: result.bucketResultToCollect)
                    return result
                } catch {
                    // jobQueue is not associated with bucketId, move over to the next jobQueue
                }
            }
            
            throw MultipleQueuesBucketResultAcceptorError.noMatchingQueueFound(
                bucketId: bucketId,
                workerId: workerId
            )
        }
    }
}

public enum MultipleQueuesBucketResultAcceptorError: Error, CustomStringConvertible {
    case noMatchingQueueFound(bucketId: BucketId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let bucketId, let workerId):
            return "Can't accept result for \(bucketId): no matching queue found for testing result from \(workerId)"
        }
    }
}
