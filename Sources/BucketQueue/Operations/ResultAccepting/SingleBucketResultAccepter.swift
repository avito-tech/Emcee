import BucketQueueModels
import Foundation
import EmceeLogging
import QueueModels
import RunnerModels
import TestHistoryTracker

public final class SingleBucketResultAcceptor: BucketResultAcceptor {
    private let bucketQueueHolder: BucketQueueHolder
    private let logger: ContextualLogger
    private let testingResultAcceptor: TestingResultAcceptor
    
    public init(
        bucketQueueHolder: BucketQueueHolder,
        logger: ContextualLogger,
        testingResultAcceptor: TestingResultAcceptor
    ) {
        self.bucketQueueHolder = bucketQueueHolder
        self.logger = logger
        self.testingResultAcceptor = testingResultAcceptor
    }
    
    public func accept(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try bucketQueueHolder.performWithExclusiveAccess {
            let previouslyDequeuedBucket = try previouslyDequeuedBucket(
                bucketId: bucketId,
                workerId: workerId
            )
            
            switch bucketResult {
            case .testingResult(let testingResult):
                return BucketQueueAcceptResult(
                    dequeuedBucket: previouslyDequeuedBucket,
                    bucketResultToCollect: .testingResult(
                        try testingResultAcceptor.acceptTestingResult(
                            dequeuedBucket: previouslyDequeuedBucket,
                            testingResult: testingResult
                        )
                    )
                )
            }
        }
    }
    
    private func previouslyDequeuedBucket(
        bucketId: BucketId,
        workerId: WorkerId
    ) throws -> DequeuedBucket {
        logger.debug("Validating result for \(bucketId) from \(workerId)")
        
        guard let previouslyDequeuedBucket = bucketQueueHolder.allDequeuedBuckets.first(where: {
            $0.enqueuedBucket.bucket.bucketId == bucketId && $0.workerId == workerId
        }) else {
            throw BucketQueueAcceptanceError.noDequeuedBucket(bucketId: bucketId, workerId: workerId)
        }
        return previouslyDequeuedBucket
    }
    
    
}
