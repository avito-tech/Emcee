import EmceeLogging
import EmceeLoggingModels
import Foundation
import LogStreamingModels
import QueueModels

/// Streamer used by a queue which determines where logs should be streamed.
public final class QueueSideLogStreamer: LogStreamer {
    private let clientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider
    private let localLogStreamer: LogStreamer
    private let queueLogStreamingModes: QueueLogStreamingModes
        
    public init(
        clientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider,
        localLogStreamer: LogStreamer,
        queueLogStreamingModes: QueueLogStreamingModes
    ) {
        self.clientSpecificLogStreamerProvider = clientSpecificLogStreamerProvider
        self.localLogStreamer = localLogStreamer
        self.queueLogStreamingModes = queueLogStreamingModes
    }
    
    public func stream(logEntry: LogEntry) {
        if queueLogStreamingModes.streamsToLocalLog {
            localLogStreamer.stream(logEntry: logEntry)
        }
        
        if queueLogStreamingModes.streamsToClient {
            let bucketId = logEntry.coordinates.first {
                $0.name == LogEntryCoordinate.bucketIdCordinateName
            }?.value.map { BucketId($0) }
            
            stream(logEntry: logEntry, bucketId: bucketId)
        }
    }
    
    private func stream(
        logEntry: LogEntry,
        bucketId: BucketId?
    ) {
        let streamer: LogStreamer
        
        if let bucketId = bucketId {
            streamer = clientSpecificLogStreamerProvider.logStreamerToClientCreatedBucketId(bucketId: bucketId)
        } else {
            streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        }
        
        streamer.stream(logEntry: logEntry)
    }
}
