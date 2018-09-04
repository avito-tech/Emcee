import Foundation

public enum VersionError: Error, CustomStringConvertible {
    case invalidIosVersion(String)
    
    public var description: String {
        switch self {
        case .invalidIosVersion(let version):
            return "Invalid runtime version '\(version)'. Expected the version to be in format '10.3' or '10.3.1'"
        }
    }
}
