import Foundation
import QueueModels

public enum NoQueueForJobIdFoundError: Error, CustomStringConvertible {
    case noQueue(jobId: JobId)
    
    public var description: String {
        switch self {
        case .noQueue(let jobId):
            return "Can't find queue for for \(jobId)"
        }
    }
}
