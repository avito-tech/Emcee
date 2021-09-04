import BucketQueueModels
import QueueModels
import RunnerModels
import TestHistoryModels
import TestHistoryStorage
import UniqueIdentifierGenerator

public final class TestHistoryTrackerImpl: TestHistoryTracker {
    private let testHistoryStorage: TestHistoryStorage
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        testHistoryStorage: TestHistoryStorage,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.testHistoryStorage = testHistoryStorage
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func bucketToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedBucket],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedBucket? {
        let bucketThatWasNotFailingOnWorkerOrNil = queue.first { enqueuedBucket in
            !bucketWasFailingOnWorker(bucket: enqueuedBucket.bucket, workerId: workerId)
        }
        
        if let bucketToDequeue = bucketThatWasNotFailingOnWorkerOrNil {
            return bucketToDequeue
        } else {
            let computedWorkerIdsInWorkingCondition = workerIdsInWorkingCondition()
            
            let bucketThatWasFailingOnEveryWorkerOrNil = queue.first { enqueuedBucket in
                bucketWasFailingOnEveryWorker(
                    bucket: enqueuedBucket.bucket,
                    workerIdsInWorkingCondition: computedWorkerIdsInWorkingCondition
                )
            }
            
            return bucketThatWasFailingOnEveryWorkerOrNil
        }
    }
    
    public func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult {
        var resultsOfSuccessfulTests = [TestEntryResult]()
        var resultsOfFailedTests = [TestEntryResult]()
        var resultsOfTestsToRetry = [TestEntryResult]()
        
        for testEntryResult in testingResult.unfilteredResults {
            let id = TestEntryHistoryId(
                bucketId: bucket.bucketId,
                testEntry: testEntryResult.testEntry
            )
            
            let testEntryHistory = testHistoryStorage.registerAttempt(
                id: id,
                testEntryResult: testEntryResult,
                workerId: workerId
            )
            
            if testEntryResult.succeeded {
                resultsOfSuccessfulTests.append(testEntryResult)
            } else {
                if testEntryHistory.numberOfAttempts < numberOfAttemptsToRunTests(bucket: bucket) {
                    resultsOfTestsToRetry.append(testEntryResult)
                } else {
                    resultsOfFailedTests.append(testEntryResult)
                }
            }
        }
        
        let testingResult = TestingResult(
            testDestination: bucket.runTestsBucketPayload.testDestination,
            unfilteredResults: resultsOfSuccessfulTests + resultsOfFailedTests
        )
        
        // Every failed test produces a single bucket with itself
        let bucketsToReenqueue = try resultsOfTestsToRetry.map { testEntryResult -> Bucket in
            try bucket.with(
                newBucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                newRunTestsBucketPayload: bucket.runTestsBucketPayload.with(
                    testEntries: [testEntryResult.testEntry]
                )
            )
        }
        
        bucketsToReenqueue.forEach { reenqueuingBucket in
            reenqueuingBucket.runTestsBucketPayload.testEntries.forEach { entry in
                let id = TestEntryHistoryId(
                    bucketId: bucket.bucketId,
                    testEntry: entry
                )

                testHistoryStorage.registerReenqueuedBucketId(
                    testEntryHistoryId: id,
                    enqueuedBucketId: reenqueuingBucket.bucketId
                )
            }
        }
        
        return TestHistoryTrackerAcceptResult(
            bucketsToReenqueue: bucketsToReenqueue,
            testingResult: testingResult
        )
    }
    
    private func bucketWasFailingOnWorker(
        bucket: Bucket,
        workerId: WorkerId
    ) -> Bool {
        let onWorker: (TestEntryHistory) -> Bool = { testEntryHistory in
            testEntryHistory.isFailingOnWorker(workerId: workerId)
        }
        return bucketWasFailing(
            bucket: bucket,
            whereItWasFailing: onWorker
        )
    }
    
    private func bucketWasFailingOnEveryWorker(
        bucket: Bucket,
        workerIdsInWorkingCondition: [WorkerId]
    ) -> Bool {
        let onEveryWorker: (TestEntryHistory) -> Bool = { testEntryHistory in
            let everyWorkerFailed = workerIdsInWorkingCondition.allSatisfy { workerId in
                testEntryHistory.isFailingOnWorker(workerId: workerId)
            }
            return everyWorkerFailed
        }
        return bucketWasFailing(
            bucket: bucket,
            whereItWasFailing: onEveryWorker
        )
    }
    
    private func bucketWasFailing(
        bucket: Bucket,
        whereItWasFailing: (TestEntryHistory) -> Bool
    ) -> Bool {
        return bucket.runTestsBucketPayload.testEntries.contains { testEntry in
            testEntryWasFailing(
                testEntry: testEntry,
                bucket: bucket,
                whereItWasFailing: whereItWasFailing
            )
        }
    }
    
    private func testEntryWasFailing(
        testEntry: TestEntry,
        bucket: Bucket,
        whereItWasFailing: (TestEntryHistory) -> Bool
    ) -> Bool {
        let testEntryHistoryId = TestEntryHistoryId(
            bucketId: bucket.bucketId,
            testEntry: testEntry
        )
        let testEntryHistory = testHistoryStorage.history(id: testEntryHistoryId)
        
        return whereItWasFailing(testEntryHistory)
    }
    
    private func numberOfAttemptsToRunTests(bucket: Bucket) -> UInt {
        return 1 + bucket.runTestsBucketPayload.testExecutionBehavior.numberOfRetries
    }
}
