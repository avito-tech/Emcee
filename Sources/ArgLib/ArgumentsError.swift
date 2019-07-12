import Foundation

public enum ArgumentsError: Error, CustomStringConvertible {
    case argumentMissing(ArgumentName)
    
    public var description: String {
        switch self {
        case .argumentMissing(let name):
            return "Argument is missing: \(name)"
        }
    }
}
