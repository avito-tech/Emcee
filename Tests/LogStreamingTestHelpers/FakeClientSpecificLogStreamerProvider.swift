import EmceeLogging
import EmceeLoggingTestHelpers
import LogStreaming
import QueueModels

open class FakeClientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider {
    public init() {}
    
    public var perBucketStreamers = [BucketId: FakeLogStreamer]()
    
    public func logStreamerToClientCreatedBucketId(bucketId: BucketId) -> LogStreamer {
        if let streamer = perBucketStreamers[bucketId] {
            return streamer
        }
        
        let streamer = FakeLogStreamer()
        perBucketStreamers[bucketId] = streamer
        return streamer
    }
    
       
    public var allClientsStreamer = FakeLogStreamer()
    
    public func logStreamerToAllClients() -> LogStreamer {
        allClientsStreamer
    }
}
