import Models
import BucketQueue
import ModelsTestHelpers

final class TestHistoryStorageMock: TestHistoryStorage {
    var historyByTest = [TestEntryHistoryId: TestEntryHistory]()
    
    func set(id: TestEntryHistoryId, testRunHistory: [TestRunHistoryItem]) {
        historyByTest[id] = TestEntryHistory(
            id: id,
            testRunHistory: testRunHistory
        )
    }
    
    func history(id: TestEntryHistoryId) -> TestEntryHistory? {
        return historyByTest[id]
    }
    
    // Registers attempt, returns updated history of test entry
    func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: String)
        -> TestEntryHistory
    {
        // do nothing in mock
        let fixtures = TestEntryHistoryFixtures(testEntry: TestEntryFixtures.testEntry())
        return TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testRunHistory: []
        )
    }
}
