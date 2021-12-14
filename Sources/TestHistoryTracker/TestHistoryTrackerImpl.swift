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
    
    public func enqueuedPayloadToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedRunIosTestsPayload],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedRunIosTestsPayload? {
        let bucketThatWasNotFailingOnWorkerOrNil = queue.first { enqueuedRunIosTestsPayload in
            !bucketWasFailingOnWorker(
                bucketId: enqueuedRunIosTestsPayload.bucketId,
                testEntries: enqueuedRunIosTestsPayload.testEntries,
                workerId: workerId
            )
        }
        
        if let payloadToDequeue = bucketThatWasNotFailingOnWorkerOrNil {
            return payloadToDequeue
        } else {
            let computedWorkerIdsInWorkingCondition = workerIdsInWorkingCondition()
            
            let bucketThatWasFailingOnEveryWorkerOrNil = queue.first { enqueuedRunIosTestsPayload in
                bucketWasFailingOnEveryWorker(
                    bucketId: enqueuedRunIosTestsPayload.bucketId,
                    testEntries: enqueuedRunIosTestsPayload.testEntries,
                    workerIdsInWorkingCondition: computedWorkerIdsInWorkingCondition
                )
            }
            
            return bucketThatWasFailingOnEveryWorkerOrNil
        }
    }
    
    public func accept(
        testingResult: TestingResult,
        bucketId: BucketId,
        numberOfRetries: UInt,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult {
        var resultsOfSuccessfulTests = [TestEntryResult]()
        var resultsOfFailedTests = [TestEntryResult]()
        var resultsOfTestsToRetry = [TestEntryResult]()
        
        for testEntryResult in testingResult.unfilteredResults {
            let id = TestEntryHistoryId(
                bucketId: bucketId,
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
                if testEntryHistory.numberOfAttempts < numberOfAttemptsToRunTests(numberOfRetries: numberOfRetries) {
                    resultsOfTestsToRetry.append(testEntryResult)
                } else {
                    resultsOfFailedTests.append(testEntryResult)
                }
            }
        }
        
        let testingResult = TestingResult(
            testDestination: testingResult.testDestination,
            unfilteredResults: resultsOfSuccessfulTests + resultsOfFailedTests
        )
        
        let testEntriesToReenqueue = resultsOfTestsToRetry.map(\.testEntry)
        
        return TestHistoryTrackerAcceptResult(
            testEntriesToReenqueue: testEntriesToReenqueue,
            testingResult: testingResult
        )
    }
    
    public func willReenqueuePreviouslyFailedTests(
        whichFailedUnderBucketId oldBucketId: BucketId,
        underNewBucketIds testEntryByBucketId: [BucketId: TestEntry]
    ) {
        // Every failed test produces a single bucket with itself
        testEntryByBucketId.forEach { bucketIdWithTestEntry in
            let id = TestEntryHistoryId(
                bucketId: oldBucketId,
                testEntry: bucketIdWithTestEntry.value
            )
            testHistoryStorage.registerReenqueuedBucketId(
                testEntryHistoryId: id,
                enqueuedBucketId: bucketIdWithTestEntry.key
            )
        }
    }
    
    private func bucketWasFailingOnWorker(
        bucketId: BucketId,
        testEntries: [TestEntry],
        workerId: WorkerId
    ) -> Bool {
        let onWorker: (TestEntryHistory) -> Bool = { testEntryHistory in
            testEntryHistory.isFailingOnWorker(workerId: workerId)
        }
        return bucketWasFailing(
            bucketId: bucketId,
            testEntries: testEntries,
            whereItWasFailing: onWorker
        )
    }
    
    private func bucketWasFailingOnEveryWorker(
        bucketId: BucketId,
        testEntries: [TestEntry],
        workerIdsInWorkingCondition: [WorkerId]
    ) -> Bool {
        let onEveryWorker: (TestEntryHistory) -> Bool = { testEntryHistory in
            let everyWorkerFailed = workerIdsInWorkingCondition.allSatisfy { workerId in
                testEntryHistory.isFailingOnWorker(workerId: workerId)
            }
            return everyWorkerFailed
        }
        return bucketWasFailing(
            bucketId: bucketId,
            testEntries: testEntries,
            whereItWasFailing: onEveryWorker
        )
    }
    
    private func bucketWasFailing(
        bucketId: BucketId,
        testEntries: [TestEntry],
        whereItWasFailing: (TestEntryHistory) -> Bool
    ) -> Bool {
        return testEntries.contains { testEntry in
            testEntryWasFailing(
                testEntry: testEntry,
                bucketId: bucketId,
                whereItWasFailing: whereItWasFailing
            )
        }
    }
    
    private func testEntryWasFailing(
        testEntry: TestEntry,
        bucketId: BucketId,
        whereItWasFailing: (TestEntryHistory) -> Bool
    ) -> Bool {
        let testEntryHistoryId = TestEntryHistoryId(
            bucketId: bucketId,
            testEntry: testEntry
        )
        let testEntryHistory = testHistoryStorage.history(id: testEntryHistoryId)
        
        return whereItWasFailing(testEntryHistory)
    }
    
    private func numberOfAttemptsToRunTests(numberOfRetries: UInt) -> UInt {
        return 1 + numberOfRetries
    }
}
