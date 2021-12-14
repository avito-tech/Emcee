import BucketQueue
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import TestHistoryModels

public final class TestEntryHistoryFixtures {
    public let testEntry: TestEntry
    public let bucketId: BucketId
    
    public init(
        testEntry: TestEntry,
        bucketId: BucketId = BucketId("fixedBucketId")
    ) {
        self.testEntry = testEntry
        self.bucketId = bucketId
    }
    
    public func testEntryHistoryId() -> TestEntryHistoryId {
        return TestEntryHistoryId(
            bucketId: bucketId,
            testEntry: testEntry
        )
    }
    
    public func testEntryHistoryItem(success: Bool = true, workerId: WorkerId = "doesn't matter") -> TestEntryHistoryItem {
        return TestEntryHistoryItem(
            result: TestEntryResult.withResults(
                testEntry: testEntry,
                testRunResults: [
                    TestRunResultFixtures.testRunResult(
                        succeeded: success
                    )
                ]
            ),
            workerId: workerId
        )
    }
    
    public func testEntryResult(success: Bool = true) -> TestEntryResult {
        return TestEntryResult.withResult(
            testEntry: testEntry,
            testRunResult: TestRunResultFixtures.testRunResult(succeeded: success)
        )
    }
}
