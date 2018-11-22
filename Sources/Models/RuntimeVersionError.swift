import Foundation

public enum RuntimeVersionError: Error, CustomStringConvertible {
    case invalidRuntime(String)
    
    public var description: String {
        switch self {
        case .invalidRuntime(let version):
            return "Invalid runtime version '\(version)'. Expected the runtime to be in format '10.3' or '10.3.1'"
        }
    }
}
