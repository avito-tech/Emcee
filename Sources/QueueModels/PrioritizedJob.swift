import Foundation

public struct PrioritizedJob: Hashable, Codable, CustomStringConvertible {    
    public let jobGroupId: JobGroupId
    public let jobGroupPriority: Priority
    public let jobId: JobId
    public let jobPriority: Priority
    public let persistentMetricsJobId: String

    public init(
        jobGroupId: JobGroupId,
        jobGroupPriority: Priority,
        jobId: JobId,
        jobPriority: Priority,
        persistentMetricsJobId: String
    ) {
        self.jobGroupId = jobGroupId
        self.jobGroupPriority = jobGroupPriority
        self.jobId = jobId
        self.jobPriority = jobPriority
        self.persistentMetricsJobId = persistentMetricsJobId
    }
    
    public var description: String {
        return "<\(type(of: self)) \(jobGroupId) \(jobGroupPriority) \(jobId) \(jobPriority) \(persistentMetricsJobId)>"
    }
}
