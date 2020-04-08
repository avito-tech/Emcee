import Foundation
import PathLib

public enum InfoPlistError: Error, CustomStringConvertible {
    case failedToReadPlistContents(path: AbsolutePath, contents: Any)
    case noValueCFBundleName(path: AbsolutePath)
    case noValueCFBundleExecutable(path: AbsolutePath)
    
    public var description: String {
        switch self {
        case .failedToReadPlistContents(let path, let contents):
            return "Unexpected contents of plist at \(path): \(contents)"
        case .noValueCFBundleName(let path):
            return "Plist at \(path) does not have a value for CFBundleName key"
        case .noValueCFBundleExecutable(let path):
            return "Plist at \(path) does not have a value for CFBundleExecutable key"
        }
    }
}
