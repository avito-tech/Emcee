import BucketQueueModels
import EmceeLogging
import Foundation
import QueueModels
import TestHistoryTracker

public final class TestingResultAcceptorImpl: TestingResultAcceptor {
    private let bucketEnqueuer: BucketEnqueuer
    private let bucketQueueHolder: BucketQueueHolder
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    
    public init(
        bucketEnqueuer: BucketEnqueuer,
        bucketQueueHolder: BucketQueueHolder,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker
    ) {
        self.bucketEnqueuer = bucketEnqueuer
        self.bucketQueueHolder = bucketQueueHolder
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
    }
    
    public func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        testingResult: TestingResult
    ) throws -> TestingResult {
        try reenqueueLostResults(
            testingResult: testingResult,
            dequeuedBucket: dequeuedBucket
        )
        
        let acceptResult = try testHistoryTracker.accept(
            testingResult: testingResult,
            bucket: dequeuedBucket.enqueuedBucket.bucket,
            workerId: dequeuedBucket.workerId
        )
        
        bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
        logger.debug("Accepted result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(dequeuedBucket.workerId)")
        
        try bucketEnqueuer.enqueue(buckets: acceptResult.bucketsToReenqueue)
        
        return acceptResult.testingResult
    }
    
    private func reenqueueLostResults(
        testingResult: TestingResult,
        dequeuedBucket: DequeuedBucket
    ) throws {
        let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(dequeuedBucket.enqueuedBucket.bucket.payload.testEntries)
        
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            logger.debug("Test result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(dequeuedBucket.workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: testingResult.testDestination,
                    unfilteredResults: lostTestEntries.map { .lost(testEntry: $0) }
                ),
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: dequeuedBucket.workerId
            )
            
            try bucketEnqueuer.enqueue(buckets: lostResult.bucketsToReenqueue)
        }
    }
}
