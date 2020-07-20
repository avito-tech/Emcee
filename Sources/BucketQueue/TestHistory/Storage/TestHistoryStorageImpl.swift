import Models
import QueueModels
import RunnerModels

public final class TestHistoryStorageImpl: TestHistoryStorage {
    private var historyByTest = [TestEntryHistoryId: TestEntryHistory]()
    
    public init() {
    }
    
    public func history(id: TestEntryHistoryId) -> TestEntryHistory {
        return historyByTest[id]
            ?? TestEntryHistory(id: id, testEntryHistoryItems: [])
    }
    
    public func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: WorkerId)
        -> TestEntryHistory
    {
        let history = historyByTest[
            id,
            default: TestEntryHistory(id: id, testEntryHistoryItems: [])
        ]
        
        let newItem = TestEntryHistoryItem(
            result: testEntryResult,
            workerId: workerId
        )
        
        let newHistory = TestEntryHistory(
            id: id,
            testEntryHistoryItems: history.testEntryHistoryItems + [newItem]
        )
        
        historyByTest[id] = newHistory
        
        return newHistory
    }
    
    public func registerReenqueuedBucketId(
        testEntryHistoryId: TestEntryHistoryId,
        enqueuedBucketId: BucketId
    ) {
        
        let newTestEntryHistoryId = TestEntryHistoryId(
            bucketId: enqueuedBucketId,
            testEntry: testEntryHistoryId.testEntry
        )
        
        let oldHistory = historyByTest[
            testEntryHistoryId,
            default: TestEntryHistory(id: newTestEntryHistoryId, testEntryHistoryItems: [])
        ]
        
        let newHistory = TestEntryHistory(
            id: newTestEntryHistoryId,
            testEntryHistoryItems: oldHistory.testEntryHistoryItems
        )
        
        historyByTest[testEntryHistoryId] = nil
        historyByTest[newTestEntryHistoryId] = newHistory
    }
}
