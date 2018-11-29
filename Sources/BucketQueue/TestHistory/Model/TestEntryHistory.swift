import Models

public final class TestRunHistoryItem: Equatable {
    public let result: TestEntryResult
    public let workerId: String
    
    public init(
        result: TestEntryResult,
        workerId: String)
    {
        self.result = result
        self.workerId = workerId
    }
    
    public static func ==(left: TestRunHistoryItem, right: TestRunHistoryItem) -> Bool {
        return left.result == right.result
            && left.workerId == right.workerId
    }
}

public final class TestEntryHistory: Equatable {
    public let id: TestEntryHistoryId
    public let testRunHistory: [TestRunHistoryItem]
    
    public init(
        id: TestEntryHistoryId,
        testRunHistory: [TestRunHistoryItem])
    {
        self.id = id
        self.testRunHistory = testRunHistory
    }
    
    // Returns true if test was executed on worker and every attempt failed
    public func isFailingOnWorker(workerId: String) -> Bool {
        let allAttemptsOnWorker = testRunHistory.filter { testRunHistoryItem in
            testRunHistoryItem.workerId == workerId
        }
        let containsSuccesses = allAttemptsOnWorker.contains { testRunHistoryItem in
            testRunHistoryItem.result.succeeded
        }
        return !allAttemptsOnWorker.isEmpty && !containsSuccesses
    }
    
    public var numberOfAttempts: Int {
        return testRunHistory.count
    }
    
    public static func ==(left: TestEntryHistory, right: TestEntryHistory) -> Bool {
        return left.id == right.id
            && left.testRunHistory == right.testRunHistory
    }
}
