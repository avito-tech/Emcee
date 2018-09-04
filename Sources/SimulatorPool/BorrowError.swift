import Foundation

public enum BorrowError: Error, CustomStringConvertible {
    case noSimulatorsLeft
    
    public var description: String {
        switch self {
        case .noSimulatorsLeft:
            return "Attempted to borrow a simulator, but simulator pool has no free simulators"
        }
    }
}
