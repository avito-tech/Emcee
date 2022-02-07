import Foundation

/// Defines what logs should be streamed into client.
public enum ClientLogStreamingMode: String, Codable, Hashable {
    
    /// Stream back only job specific logs. Global logs are not streamed back into client.
    case jobSpecific
    
    /// Log streaming is enabled for all logs: job-specific and global
    case all
    
    /// Log streaming feature is disabled
    case disabled

    public var allowsJobSpecificLogStreaming: Bool {
        return self == .jobSpecific || self == .all
    }
    
    public var allowsGlobalLogStreaming: Bool {
        return self == .all
    }
}
