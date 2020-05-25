import Foundation

/// This is a plist root object. Plists may have only an array or dict as their root objects.
public enum RootPlistEntry: CustomStringConvertible, Equatable {
    case array([PlistEntry])
    case dict([String: PlistEntry])
    
    /// Provides `PlistEntry` from this root object, this should be used to query plist.
    public var plistEntry: PlistEntry {
        switch self {
        case .array(let value):
            return .array(value)
        case .dict(let value):
            return .dict(value)
        }
    }
    
    public var description: String {
        switch self {
        case .array(let element):
            return "<Root array \(element)>"
        case .dict(let element):
            return "<Root dict \(element)>"
        }
    }
}
