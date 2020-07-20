import Models
import QueueModels
import RunnerModels

public final class TestEntryHistoryItem: Equatable {
    public let result: TestEntryResult
    public let workerId: WorkerId
    
    public init(
        result: TestEntryResult,
        workerId: WorkerId)
    {
        self.result = result
        self.workerId = workerId
    }
    
    public static func ==(left: TestEntryHistoryItem, right: TestEntryHistoryItem) -> Bool {
        return left.result == right.result
            && left.workerId == right.workerId
    }
}
