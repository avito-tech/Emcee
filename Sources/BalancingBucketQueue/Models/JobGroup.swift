import Foundation
import QueueModels

public struct JobGroup: Hashable, DefinesExecutionOrder {
    public let creationTime: Date
    public let jobGroupId: JobGroupId
    public let priority: Priority
    
    public init(
        creationTime: Date,
        jobGroupId: JobGroupId,
        priority: Priority
    ) {
        self.creationTime = creationTime
        self.jobGroupId = jobGroupId
        self.priority = priority
    }
    
    public func executionOrder(relativeTo other: JobGroup) -> ExecutionOrder {
        guard priority == other.priority else {
            return priority.executionOrder(relativeTo: other.priority)
        }
        guard creationTime == other.creationTime else {
            return creationTime < other.creationTime ? .before : .after
        }
        return .equal
    }
}
