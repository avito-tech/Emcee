import Foundation
import Models

public enum LocalQueueServerError: Error, CustomStringConvertible {
    case sameVersionQueueIsAlreadyRunning(port: Int, version: Version)
    
    public var description: String {
        switch self {
        case .sameVersionQueueIsAlreadyRunning(let port, let version):
            return "Queue server with version \(version) is already running on port \(port)"
        }
    }
}
