import Foundation
import Models

public enum ValidationError: Error, CustomStringConvertible {
    case unexpectedExtension(ResolvableResourceLocation, actual: String, expected: String)
    case noExecutableFound(ResolvableResourceLocation, expectedLocation: String)
    case noPluginsFound(ResolvableResourceLocation)
    
    public var description: String {
        switch self {
        case let .unexpectedExtension(resource, actual, expected):
            return "Plugin bundle at '\(resource)' has unexpected extension '.\(actual)'. Plugins must have '.\(expected)' extension."
        case let .noExecutableFound(resource, expectedLocation):
            return "Plugin at '\(resource)' has no executable at expected location: '\((expectedLocation))'"
        case let .noPluginsFound(resource):
            return "No plugins found at: '\(resource)'"
        }
    }
}
