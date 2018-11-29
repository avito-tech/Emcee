import Models
@testable import BucketQueue
import ModelsTestHelpers

final class TestEntryHistoryFixtures {
    let testEntry: TestEntry
    let bucket: Bucket
    
    init(testEntry: TestEntry, bucket: Bucket? = nil) {
        self.testEntry = testEntry
        self.bucket = bucket ?? BucketFixtures.createBucket(testEntries: [testEntry])
    }
    
    func testEntryHistoryId() -> TestEntryHistoryId {
        return TestEntryHistoryId(
            testEntry: testEntry,
            bucket: bucket
        )
    }
    
    func testRunHistoryItem(success: Bool = true, workerId: String = "doesn't matter") -> TestRunHistoryItem {
        return TestRunHistoryItem(
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
    
    func testEntryResult(success: Bool = true) -> TestEntryResult {
        return TestEntryResult.withResult(
            testEntry: testEntry,
            testRunResult: TestRunResultFixtures.testRunResult(succeeded: success)
        )
    }
}
