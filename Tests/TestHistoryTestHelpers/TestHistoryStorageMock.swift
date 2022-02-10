import CommonTestModels
import CommonTestModelsTestHelpers
import TestHistoryModels
import TestHistoryStorage
import QueueModels

public final class TestHistoryStorageMock: TestHistoryStorage {
    public init() {}
    
    public var historyByTest = [TestEntryHistoryId: TestEntryHistory]()
    
    public func set(id: TestEntryHistoryId, testEntryHistoryItems: [TestEntryHistoryItem]) {
        historyByTest[id] = TestEntryHistory(
            id: id,
            testEntryHistoryItems: testEntryHistoryItems
        )
    }
    
    public func history(id: TestEntryHistoryId) -> TestEntryHistory {
        return historyByTest[id] ?? TestEntryHistory(id: id, testEntryHistoryItems: [])
    }
    
    // Registers attempt, returns updated history of test entry
    public func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: WorkerId
    ) -> TestEntryHistory {
        // do nothing in mock
        let fixtures = TestEntryHistoryFixtures(testEntry: TestEntryFixtures.testEntry())
        return TestEntryHistory(
            id: fixtures.testEntryHistoryId(),
            testEntryHistoryItems: []
        )
    }
    
    public func registerReenqueuedBucketId(testEntryHistoryId: TestEntryHistoryId, enqueuedBucketId: BucketId) {
        // do nothing in mock
    }
}
