import Foundation
import PathLib

public enum ProcessControllerError: CustomStringConvertible, Error {
    case fileIsNotExecutable(path: AbsolutePath)
    
    public var description: String {
        switch self {
        case .fileIsNotExecutable(let path):
            return "File is not executable: \(path)"
        }
    }
}
