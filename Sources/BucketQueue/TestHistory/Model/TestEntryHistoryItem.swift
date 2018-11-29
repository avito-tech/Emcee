import Models

public final class TestEntryHistoryItem: Equatable {
    public let result: TestEntryResult
    public let workerId: String
    
    public init(
        result: TestEntryResult,
        workerId: String)
    {
        self.result = result
        self.workerId = workerId
    }
    
    public static func ==(left: TestEntryHistoryItem, right: TestEntryHistoryItem) -> Bool {
        return left.result == right.result
            && left.workerId == right.workerId
    }
}
