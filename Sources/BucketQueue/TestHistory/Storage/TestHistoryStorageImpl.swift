import Models

public final class TestHistoryStorageImpl: TestHistoryStorage {
    private var historyByTest = [TestEntryHistoryId: TestEntryHistory]()
    
    public init() {
    }
    
    public func history(id: TestEntryHistoryId) -> TestEntryHistory? {
        return historyByTest[id]
    }
    
    public func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: String)
        -> TestEntryHistory
    {
        let history = historyByTest[
            id,
            default: TestEntryHistory(id: id, testRunHistory: [])
        ]
        
        let newItem = TestRunHistoryItem(
            result: testEntryResult,
            workerId: workerId
        )
        
        let newHistory = TestEntryHistory(
            id: id,
            testRunHistory: history.testRunHistory + [newItem]
        )
        
        historyByTest[id] = newHistory
        
        return newHistory
    }
}
