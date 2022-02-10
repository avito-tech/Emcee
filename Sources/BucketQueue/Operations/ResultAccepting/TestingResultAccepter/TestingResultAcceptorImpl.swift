import BucketQueueModels
import CommonTestModels
import EmceeLogging
import Foundation
import QueueModels
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
        bucketPayloadWithTests: BucketPayloadWithTests,
        testingResult: TestingResult
    ) throws -> TestingResult {
        let bucket = dequeuedBucket.enqueuedBucket.bucket
        let workerId = dequeuedBucket.workerId
        
        try reenqueueLostResults(
            bucket: bucket,
            bucketPayloadWithTests: bucketPayloadWithTests,
            testingResult: testingResult,
            workerId: workerId
        )
        
        let acceptResult = try testHistoryTracker.accept(
            testingResult: testingResult,
            bucketId: bucket.bucketId,
            numberOfRetries: bucketPayloadWithTests.testExecutionBehavior.numberOfRetries,
            workerId: workerId
        )
        
        bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
        logger.debug("Accepted result for \(bucket.bucketId) from \(workerId)")
        
        try reenqueue(
            testEntries: acceptResult.testEntriesToReenqueue,
            originalBucket: dequeuedBucket.enqueuedBucket.bucket
        )
        
        return acceptResult.testingResult
    }
    
    private func reenqueueLostResults(
        bucket: Bucket,
        bucketPayloadWithTests: BucketPayloadWithTests,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws {
        let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
        let expectedTestEntries = Set(bucketPayloadWithTests.testEntries)
        
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            logger.debug("Test result for \(bucket.bucketId) from \(workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: testingResult.testDestination,
                    unfilteredResults: lostTestEntries.map { .lost(testEntry: $0) }
                ),
                bucketId: bucket.bucketId,
                numberOfRetries: bucketPayloadWithTests.testExecutionBehavior.numberOfRetries,
                workerId: workerId
            )
            
            try reenqueue(
                testEntries: lostResult.testEntriesToReenqueue,
                originalBucket: bucket
            )
        }
    }
    
    private func reenqueue(
        testEntries: [TestEntry],
        originalBucket: Bucket
    ) throws {
        guard !testEntries.isEmpty else { return }
        
        var buckets = [Bucket]()
        var testEntryByBucketId = [BucketId: TestEntry]()
        
        try testEntries.forEach { testEntry in
            let newPayloadContainer: BucketPayloadContainer
            switch originalBucket.payloadContainer {
            case .runAndroidTests(let payload):
                newPayloadContainer = .runAndroidTests(payload.with(testEntries: [testEntry]))
            case .runAppleTests(let payload):
                newPayloadContainer = .runAppleTests(payload.with(testEntries: [testEntry]))
            }
            
            let newBucket = try originalBucket.with(
                newBucketId: BucketId(uniqueIdentifierGenerator.generate()),
                newPayloadContainer: newPayloadContainer
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
