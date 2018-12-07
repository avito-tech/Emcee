import Models

public final class TestHistoryTrackerImpl: TestHistoryTracker {
    private let testHistoryStorage: TestHistoryStorage
    private let numberOfAttemptsToRunTests: UInt
    
    public init(
        numberOfRetries: UInt,
        testHistoryStorage: TestHistoryStorage)
    {
        self.numberOfAttemptsToRunTests = 1 + numberOfRetries
        self.testHistoryStorage = testHistoryStorage
    }
    
    public func bucketToDequeue(
        workerId: String,
        queue: [Bucket],
        aliveWorkers: @autoclosure () -> [String])
        -> Bucket?
    {
        let bucketThatWasNotFailingOnWorkerOrNil = queue.first { bucket in
            !bucketWasFailingOnWorker(bucket: bucket, workerId: workerId)
        }
        
        if let bucketToDequeue = bucketThatWasNotFailingOnWorkerOrNil {
            return bucketToDequeue
        } else {
            let computedAliveWorkers = aliveWorkers()
            
            let bucketThatWasFailingOnEveryWorkerOrNil = queue.first { bucket in
                bucketWasFailingOnEveryWorker(
                    bucket: bucket,
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
        -> TestHistoryTrackerAcceptResult
    {
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
                if testEntryHistory.numberOfAttempts < numberOfAttemptsToRunTests {
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
                testEntries: [testEntryResult.testEntry],
                buildArtifacts: bucket.buildArtifacts,
                environment: bucket.environment,
                simulatorSettings: bucket.simulatorSettings,
                testDestination: bucket.testDestination,
                toolResources: bucket.toolResources
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
}
