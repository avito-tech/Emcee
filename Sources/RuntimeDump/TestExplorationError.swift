import Foundation

public enum TestExplorationError: Error, CustomStringConvertible {
    case fileNotFound(String)
    
    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Runtime dump did not create a JSON file at expected location: '\(path)'."
        }
    }
}
