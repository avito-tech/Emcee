import Foundation

public enum CommandExecutionError: Error, CustomStringConvertible {
    case incorrectUsage(usageDescription: String)
    
    public var description: String {
        switch self {
        case .incorrectUsage(let usageDescription):
            return "Incorrect arguments. Usage:\n\(usageDescription)"
        }
    }
}
