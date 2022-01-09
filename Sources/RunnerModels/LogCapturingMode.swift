import Foundation

public enum LogCapturingMode: String, Codable, Hashable, CustomStringConvertible {
    /// Attempt to capture all output during test invocation
    case allLogs
    
    /// Attempt to capture only crash logs, skipping other logs
    case onlyCrashLogs
    
    /// Do not capture any logs
    case noLogs
    
    public var description: String { rawValue }
}
