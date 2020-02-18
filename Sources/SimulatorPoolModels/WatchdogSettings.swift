import Foundation

public struct WatchdogSettings: Codable, CustomStringConvertible, Hashable {
    
    /// Array of bundle IDs which watchdog timer config should be overriden
    public let bundleIds: [String]
    
    /// Custom watchdog timeout value for bundle IDs above
    public let timeout: Int
    
    public init(
        bundleIds: [String],
        timeout: Int
    ) {
        self.bundleIds = bundleIds
        self.timeout = timeout
    }
    
    public var description: String {
        return "<\(type(of: self)) timeout: \(timeout) bundles: \(bundleIds)>"
    }
}
