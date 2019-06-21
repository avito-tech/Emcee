import Models

public final class TestEntryHistory: Equatable {
    public let id: TestEntryHistoryId
    public let testEntryHistoryItems: [TestEntryHistoryItem]
    
    public init(
        id: TestEntryHistoryId,
        testEntryHistoryItems: [TestEntryHistoryItem])
    {
        self.id = id
        self.testEntryHistoryItems = testEntryHistoryItems
    }
    
    // Returns true if test was executed on worker and every attempt failed
    public func isFailingOnWorker(workerId: WorkerId) -> Bool {
        let allAttemptsOnWorker = testEntryHistoryItems.filter { testEntryHistoryItem in
            testEntryHistoryItem.workerId == workerId
        }
        let containsSuccesses = allAttemptsOnWorker.contains { testEntryHistoryItem in
            testEntryHistoryItem.result.succeeded
        }
        return !allAttemptsOnWorker.isEmpty && !containsSuccesses
    }
    
    public var numberOfAttempts: Int {
        return testEntryHistoryItems.count
    }
    
    public static func ==(left: TestEntryHistory, right: TestEntryHistory) -> Bool {
        return left.id == right.id
            && left.testEntryHistoryItems == right.testEntryHistoryItems
    }
}
