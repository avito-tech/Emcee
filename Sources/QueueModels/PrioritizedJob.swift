import Foundation
import Models

public struct PrioritizedJob: Hashable, Codable, CustomStringConvertible {    
    public let jobGroupId: JobGroupId
    public let jobGroupPriority: Priority
    public let jobId: JobId
    public let jobPriority: Priority

    public init(
        jobGroupId: JobGroupId,
        jobGroupPriority: Priority,
        jobId: JobId,
        jobPriority: Priority
    ) {
        self.jobGroupId = jobGroupId
        self.jobGroupPriority = jobGroupPriority
        self.jobId = jobId
        self.jobPriority = jobPriority
    }
    
    public var description: String {
        return "<\(type(of: self)) \(jobGroupId) \(jobGroupPriority) \(jobId) \(jobPriority)>"
    }
}
