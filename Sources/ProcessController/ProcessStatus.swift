import Foundation

public enum ProcessStatus: Equatable, CustomStringConvertible {
    case notStarted
    case stillRunning
    case terminated(exitCode: Int32)
    
    public var description: String {
        switch self {
        case .notStarted:
            return "not started"
        case .stillRunning:
            return "still running"
        case .terminated(let exitCode):
            return "exit code \(exitCode)"
        }
    }
}
