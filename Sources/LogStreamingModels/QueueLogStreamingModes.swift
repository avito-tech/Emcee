import Foundation

public struct QueueLogStreamingModes: Codable, Hashable {
    public let streamsToClient: Bool
    public let streamsToLocalLog: Bool
    
    public init(
        streamsToClient: Bool,
        streamsToLocalLog: Bool
    ) {
        self.streamsToClient = streamsToClient
        self.streamsToLocalLog = streamsToLocalLog
    }
}
