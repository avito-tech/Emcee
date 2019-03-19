import Foundation

public final class PrioritizedJob: Hashable, Codable, CustomStringConvertible {
    public let jobId: JobId
    public let priority: Priority

    public init(jobId: JobId, priority: Priority) {
        self.jobId = jobId
        self.priority = priority
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(jobId)
        hasher.combine(priority)
    }
    
    public var description: String {
        return "<\(type(of: self)) jobId: \(jobId) priority: \(priority)>"
    }
    
    public static func == (left: PrioritizedJob, right: PrioritizedJob) -> Bool {
        return left.jobId == right.jobId
            && left.priority == right.priority
    }
}
