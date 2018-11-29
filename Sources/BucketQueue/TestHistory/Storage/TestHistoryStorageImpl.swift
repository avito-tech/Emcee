import Models

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
        workerId: String)
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
}
