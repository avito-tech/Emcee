import Foundation
import Models

public enum WorkerConfigurationError: Error, CustomStringConvertible {
    case missingWorkerConfiguration(workerId: WorkerId)
    
    public var description: String {
        switch self {
        case .missingWorkerConfiguration(let workerId):
            return "Missing worker configuration for \(workerId)"
        }
    }
}
