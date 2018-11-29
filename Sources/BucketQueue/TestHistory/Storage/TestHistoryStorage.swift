import Models

public protocol TestHistoryStorage {
    func history(id: TestEntryHistoryId) -> TestEntryHistory?
    
    // Registers attempt, returns updated history of test entry
    func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: String)
        -> TestEntryHistory
}
