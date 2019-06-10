import Models
import BucketQueue
import ModelsTestHelpers

public final class TestEntryHistoryFixtures {
    public let testEntry: TestEntry
    public let bucket: Bucket
    
    public init(testEntry: TestEntry, bucket: Bucket? = nil) {
        self.testEntry = testEntry
        self.bucket = bucket ?? BucketFixtures.createBucket(testEntries: [testEntry])
    }
    
    public func testEntryHistoryId() -> TestEntryHistoryId {
        return TestEntryHistoryId(
            testEntry: testEntry,
            bucket: bucket
        )
    }
    
    public func testEntryHistoryItem(success: Bool = true, workerId: String = "doesn't matter") -> TestEntryHistoryItem {
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
