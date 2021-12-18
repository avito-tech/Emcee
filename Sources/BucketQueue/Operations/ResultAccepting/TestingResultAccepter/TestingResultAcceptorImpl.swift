import BucketQueueModels
import EmceeLogging
import Foundation
import QueueModels
import RunnerModels
import TestHistoryTracker
import UniqueIdentifierGenerator

public final class TestingResultAcceptorImpl: TestingResultAcceptor {
    private let bucketEnqueuer: BucketEnqueuer
    private let bucketQueueHolder: BucketQueueHolder
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        bucketEnqueuer: BucketEnqueuer,
        bucketQueueHolder: BucketQueueHolder,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.bucketEnqueuer = bucketEnqueuer
        self.bucketQueueHolder = bucketQueueHolder
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        runIosTestsPayload: RunIosTestsPayload,
        testingResult: TestingResult
    ) throws -> TestingResult {
        let bucket = dequeuedBucket.enqueuedBucket.bucket
        let workerId = dequeuedBucket.workerId
        
        try reenqueueLostResults(
            bucket: bucket,
            runIosTestsPayload: runIosTestsPayload,
            testingResult: testingResult,
            workerId: workerId
        )
        
        let acceptResult = try testHistoryTracker.accept(
            testingResult: testingResult,
            bucketId: bucket.bucketId,
            numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries,
            workerId: workerId
        )
        
        bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
        logger.debug("Accepted result for \(bucket.bucketId) from \(workerId)")
        
        try reenqueue(
            testEntries: acceptResult.testEntriesToReenqueue,
            originalBucket: dequeuedBucket.enqueuedBucket.bucket,
            originalRunIosTestsPayload: runIosTestsPayload
        )
        
        return acceptResult.testingResult
    }
    
    private func reenqueueLostResults(
        bucket: Bucket,
        runIosTestsPayload: RunIosTestsPayload,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws {
        let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(runIosTestsPayload.testEntries)
        
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            logger.debug("Test result for \(bucket.bucketId) from \(workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: testingResult.testDestination,
                    unfilteredResults: lostTestEntries.map { .lost(testEntry: $0) }
                ),
                bucketId: bucket.bucketId,
                numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries,
                workerId: workerId
            )
            
            try reenqueue(
                testEntries: lostResult.testEntriesToReenqueue,
                originalBucket: bucket,
                originalRunIosTestsPayload: runIosTestsPayload
            )
        }
    }
    
    private func reenqueue(
        testEntries: [TestEntry],
        originalBucket: Bucket,
        originalRunIosTestsPayload: RunIosTestsPayload
    ) throws {
        guard !testEntries.isEmpty else { return }
        
        var buckets = [Bucket]()
        var testEntryByBucketId = [BucketId: TestEntry]()
        
        try testEntries.forEach { testEntry in
            let newBucket = try originalBucket.with(
                newBucketId: BucketId(uniqueIdentifierGenerator.generate()),
                newPayload: .runIosTests(
                    originalRunIosTestsPayload.with(
                        testEntries: [testEntry]
                    )
                )
            )
            buckets.append(newBucket)
            testEntryByBucketId[newBucket.bucketId] = testEntry
        }
        
        testHistoryTracker.willReenqueuePreviouslyFailedTests(
            whichFailedUnderBucketId: originalBucket.bucketId,
            underNewBucketIds: testEntryByBucketId
        )
        
        try bucketEnqueuer.enqueue(buckets: buckets)
    }
}
