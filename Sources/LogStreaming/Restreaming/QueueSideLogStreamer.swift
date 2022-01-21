import EmceeLogging
import EmceeLoggingModels
import Foundation
import QueueModels

/// Streamer used by a queue which determines where logs should be streamed.
public final class QueueSideLogStreamer: LogStreamer {
    private let clientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider
    private let localLogStreamer: LogStreamer
        
    public init(
        clientSpecificLogStreamerProvider: ClientSpecificLogStreamerProvider,
        localLogStreamer: LogStreamer
    ) {
        self.clientSpecificLogStreamerProvider = clientSpecificLogStreamerProvider
        self.localLogStreamer = localLogStreamer
    }
    
    public func stream(logEntry: LogEntry) {
        localLogStreamer.stream(logEntry: logEntry)
        
        let bucketId = logEntry.coordinates.first {
            $0.name == ContextualLogger.ContextKeys.bucketId.rawValue
        }?.value.map { BucketId($0) }
        
        stream(logEntry: logEntry, bucketId: bucketId)
    }
    
    private func stream(
        logEntry: LogEntry,
        bucketId: BucketId?
    ) {
        let streamer: LogStreamer
        
        if let bucketId = bucketId {
            streamer = clientSpecificLogStreamerProvider.logStreamerForStreamingLogsIntoClientCreatedBucketId(bucketId: bucketId)
        } else {
            streamer = clientSpecificLogStreamerProvider.logStreamerToAllClients()
        }
        
        streamer.stream(logEntry: logEntry)
    }
}
