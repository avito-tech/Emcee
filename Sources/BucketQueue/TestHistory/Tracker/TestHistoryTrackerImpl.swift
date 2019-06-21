import Models
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
        workerId: String,
        queue: [EnqueuedBucket],
        aliveWorkers: @autoclosure () -> [String])
        -> EnqueuedBucket?
    {
        let bucketThatWasNotFailingOnWorkerOrNil = queue.first { enqueuedBucket in
            !bucketWasFailingOnWorker(bucket: enqueuedBucket.bucket, workerId: workerId)
        }
        
        if let bucketToDequeue = bucketThatWasNotFailingOnWorkerOrNil {
            return bucketToDequeue
        } else {
            let computedAliveWorkers = aliveWorkers()
            
            let bucketThatWasFailingOnEveryWorkerOrNil = queue.first { enqueuedBucket in
                bucketWasFailingOnEveryWorker(
                    bucket: enqueuedBucket.bucket,
                    aliveWorkers: computedAliveWorkers
                )
            }
            
            return bucketThatWasFailingOnEveryWorkerOrNil
        }
    }
    
    public func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: String)
        throws
        -> TestHistoryTrackerAcceptResult
    {
        guard testingResult.bucketId == bucket.bucketId else {
            throw TestHistoryTrackerError.mismatchedBuckedIds(
                testingResultBucketId: testingResult.bucketId,
                bucketId: bucket.bucketId
            )
        }

        var resultsOfSuccessfulTests = [TestEntryResult]()
        var resultsOfFailedTests = [TestEntryResult]()
        var resultsOfTestsToRetry = [TestEntryResult]()
        
        for testEntryResult in testingResult.unfilteredResults {
            let id = TestEntryHistoryId(testEntry: testEntryResult.testEntry, bucket: bucket)
            
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
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: resultsOfSuccessfulTests + resultsOfFailedTests
        )
        
        // Every failed test produces a single bucket with itself
        let bucketsToReenqueue = resultsOfTestsToRetry.map { testEntryResult in
            Bucket(
                bucketId: uniqueIdentifierGenerator.generate(),
                testEntries: [testEntryResult.testEntry],
                buildArtifacts: bucket.buildArtifacts,
                simulatorSettings: bucket.simulatorSettings,
                testDestination: bucket.testDestination,
                testExecutionBehavior: bucket.testExecutionBehavior,
                toolResources: bucket.toolResources,
                testType: bucket.testType
            )
        }
        
        return TestHistoryTrackerAcceptResult(
            bucketsToReenqueue: bucketsToReenqueue,
            testingResult: testingResult
        )
    }
    
    private func bucketWasFailingOnWorker(
        bucket: Bucket,
        workerId: String)
        -> Bool
    {
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
        aliveWorkers: [String])
        -> Bool
    {
        let onEveryWorker: (TestEntryHistory) -> Bool = { testEntryHistory in
            let everyWorkerFailed = aliveWorkers.allSatisfy { workerId in
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
        whereItWasFailing: (TestEntryHistory) -> Bool)
        -> Bool
    {
        return bucket.testEntries.contains { testEntry in
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
        whereItWasFailing: (TestEntryHistory) -> Bool)
        -> Bool
    {
        let testEntryHistoryId = TestEntryHistoryId(testEntry: testEntry, bucket: bucket)
        let testEntryHistory = testHistoryStorage.history(id: testEntryHistoryId)
        
        return whereItWasFailing(testEntryHistory)
    }
    
    private func numberOfAttemptsToRunTests(bucket: Bucket) -> UInt {
        return 1 + bucket.testExecutionBehavior.numberOfRetries
    }
}
