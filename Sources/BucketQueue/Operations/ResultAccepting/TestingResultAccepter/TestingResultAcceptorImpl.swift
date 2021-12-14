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
        testingResult: TestingResult
    ) throws -> TestingResult {
        let runIosTestsPayload = try dequeuedBucket.enqueuedBucket.bucket.payload.cast(RunIosTestsPayload.self)
        
        try reenqueueLostResults(
            testingResult: testingResult,
            dequeuedBucket: dequeuedBucket,
            runIosTestsPayload: runIosTestsPayload
        )
        
        let acceptResult = try testHistoryTracker.accept(
            testingResult: testingResult,
            bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries,
            workerId: dequeuedBucket.workerId
        )
        
        bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
        logger.debug("Accepted result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(dequeuedBucket.workerId)")
        
        try reenqueue(
            testEntries: acceptResult.testEntriesToReenqueue,
            dequeuedBucket: dequeuedBucket,
            runIosTestsPayload: runIosTestsPayload
        )
        
        return acceptResult.testingResult
    }
    
    private func reenqueueLostResults(
        testingResult: TestingResult,
        dequeuedBucket: DequeuedBucket,
        runIosTestsPayload: RunIosTestsPayload
    ) throws {
        let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(runIosTestsPayload.testEntries)
        
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            logger.debug("Test result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(dequeuedBucket.workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: testingResult.testDestination,
                    unfilteredResults: lostTestEntries.map { .lost(testEntry: $0) }
                ),
                bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
                numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries,
                workerId: dequeuedBucket.workerId
            )
            
            try reenqueue(
                testEntries: lostResult.testEntriesToReenqueue,
                dequeuedBucket: dequeuedBucket,
                runIosTestsPayload: runIosTestsPayload
            )
        }
    }
    
    private func reenqueue(
        testEntries: [TestEntry],
        dequeuedBucket: DequeuedBucket,
        runIosTestsPayload: RunIosTestsPayload
    ) throws {
        guard !testEntries.isEmpty else { return }
        
        var buckets = [Bucket]()
        var testEntryByBucketId = [BucketId: TestEntry]()
        
        try testEntries.forEach { testEntry in
            let newBucket = try dequeuedBucket.enqueuedBucket.bucket.with(
                newBucketId: BucketId(uniqueIdentifierGenerator.generate()),
                newPayload: .runIosTests(
                    runIosTestsPayload.with(
                        testEntries: [testEntry]
                    )
                )
            )
            buckets.append(newBucket)
            testEntryByBucketId[newBucket.bucketId] = testEntry
        }
        
        testHistoryTracker.willReenqueuePreviouslyFailedTests(
            whichFailedUnderBucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            underNewBucketIds: testEntryByBucketId
        )
        
        try bucketEnqueuer.enqueue(buckets: buckets)
    }
}
