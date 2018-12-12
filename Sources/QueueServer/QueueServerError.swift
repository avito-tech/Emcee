import Foundation

public enum QueueServerError: Error, CustomStringConvertible {
    case noWorkers
    case missingWorkerConfigurationForWorkerId(String)
    
    public var description: String {
        switch self {
        case .noWorkers:
            return "No alive workers"
        case .missingWorkerConfigurationForWorkerId(let workerId):
            return "Missing configuration for worker '\(workerId)'"
        }
    }
}
