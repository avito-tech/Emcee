import Foundation

public enum ResourceLocationError: Error, CustomStringConvertible {
    case encodeRemoteUrl(url: String)
    
    public var description: String {
        switch self {
        case .encodeRemoteUrl(let url):
            return "Can't encode resource location for \(url)"
        }
    }
}
