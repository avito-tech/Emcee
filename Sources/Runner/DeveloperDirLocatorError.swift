import Foundation
import PathLib

public enum DeveloperDirLocatorError: Error, CustomStringConvertible {
    case unableToLoadPlist(path: AbsolutePath)
    case plistDoesNotContainCFBundleShortVersionString(path: AbsolutePath)
    case noSuitableXcode(CFBundleShortVersionString: String)
    
    public var description: String {
        switch self {
        case .unableToLoadPlist(let path):
            return "Unable to load plist at path \(path)"
        case .plistDoesNotContainCFBundleShortVersionString(let path):
            return "Plist at \(path) does not contain value for CFBundleShortVersionString key"
        case .noSuitableXcode(let CFBundleShortVersionString):
            return "Unable to locate Xcode with CFBundleShortVersionString == \(CFBundleShortVersionString)"
        }
    }
}
