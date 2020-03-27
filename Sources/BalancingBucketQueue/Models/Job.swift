import Foundation
import QueueModels

public struct Job: Hashable, DefinesExecutionOrder {
    public let creationTime: Date
    public let jobId: JobId
    public let priority: Priority
    
    public init(
        creationTime: Date,
        jobId: JobId,
        priority: Priority
    ) {
        self.creationTime = creationTime
        self.jobId = jobId
        self.priority = priority
    }
    
    public func executionOrder(relativeTo other: Job) -> ExecutionOrder {
        guard priority == other.priority else {
            return priority.executionOrder(relativeTo: other.priority)
        }
        guard creationTime == other.creationTime else {
            return creationTime < other.creationTime ? .before : .after
        }
        return .equal
    }
}
