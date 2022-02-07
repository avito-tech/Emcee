import Foundation
import QueueModels

public final class NoOpClientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider {
    public init() {}
    
    public func logStreamerToClientCreatedBucketId(
        bucketId: BucketId
    ) -> LogStreamer {
        NoOpLogStreamer.instance
    }
    
    public func logStreamerToAllClients() -> LogStreamer {
        NoOpLogStreamer.instance
    }
}
