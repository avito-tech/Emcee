import Foundation
import Models

public struct PrioritizedJob: Hashable, Codable, CustomStringConvertible {
    public let jobId: JobId
    public let priority: Priority

    public init(jobId: JobId, priority: Priority) {
        self.jobId = jobId
        self.priority = priority
    }
    
    public var description: String {
        return "<\(type(of: self)) jobId: \(jobId) priority: \(priority)>"
    }
}
