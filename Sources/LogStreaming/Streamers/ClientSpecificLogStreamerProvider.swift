import Foundation
import QueueModels

public protocol ClientSpecificLogStreamerProvider {
    /// Returns streamer suitable for streaming into client which created given `bucketId`.
    func logStreamerToClientCreatedBucketId(
        bucketId: BucketId
    ) -> LogStreamer
    
    /// Returns streamer suitable for streaming into all known clients.
    func logStreamerToAllClients() -> LogStreamer
}
