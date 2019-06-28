import Foundation
import PathLib

public enum TestExplorationError: Error, CustomStringConvertible {
    case fileNotFound(AbsolutePath)
    
    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Runtime dump did not create a JSON file at expected location: '\(path)'."
        }
    }
}
