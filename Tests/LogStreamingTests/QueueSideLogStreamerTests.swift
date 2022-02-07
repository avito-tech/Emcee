import EmceeLoggingModels
import EmceeLoggingTestHelpers
import Foundation
import LogStreaming
import LogStreamingModels
import LogStreamingTestHelpers
import QueueModels
import TestHelpers
import XCTest

final class QueueSideLogStreamerTests: XCTestCase {
    private lazy var bucketId: BucketId = "bucketId"
    private lazy var clientSpecificLogStreamerProvider = FakeClientSpecificLogStreamerProvider()
    private lazy var localLogStreamer = InMemoryLogStreamer()
    private lazy var logEntry = LogEntryFixture().logEntry()
    private lazy var queueLogStreamingModes = QueueLogStreamingModes(
        streamsToClient: true,
        streamsToLocalLog: true
    )
    private lazy var streamer = QueueSideLogStreamer(
        clientSpecificLogStreamerProvider: clientSpecificLogStreamerProvider,
        localLogStreamer: localLogStreamer,
        queueLogStreamingModes: queueLogStreamingModes
    )
    
    func test___when_no_bucketId_coordinate_is_provided___streamed_into_local_streamer() {
        streamer.stream(logEntry: logEntry)
        
        assert {
            localLogStreamer.logEntries()
        } equals: {
            [logEntry]
        }
        
        assertTrue {
            clientSpecificLogStreamerProvider.perBucketStreamers.isEmpty
        }
    }
    
    func test___when_bucketId_coordinate_is_provided___streamed_into_client_of_that_bucket() {
        logEntry = logEntry.with(
            appendedCoordinate: .bucketId(bucketId)
        )
        
        streamer.stream(logEntry: logEntry)
        
        assert {
            localLogStreamer.logEntries()
        } equals: {
            [logEntry]
        }
        
        let clientStreamer = assertNotNil {
            clientSpecificLogStreamerProvider.perBucketStreamers[bucketId]
        }
        
        assert {
            clientStreamer.capturedLogEntries
        } equals: {
            [logEntry]
        }
    }
    
    func test___when_local_log_disabled___logs_not_streamed_to_local_steeamer() {
        queueLogStreamingModes = QueueLogStreamingModes(streamsToClient: true, streamsToLocalLog: false)
        
        logEntry = logEntry.with(
            appendedCoordinate: .bucketId(bucketId)
        )
        
        streamer.stream(logEntry: logEntry)
        
        assert {
            localLogStreamer.logEntries()
        } equals: {
            []
        }
        
        let clientStreamer = assertNotNil {
            clientSpecificLogStreamerProvider.perBucketStreamers[bucketId]
        }
        
        assert {
            clientStreamer.capturedLogEntries
        } equals: {
            [logEntry]
        }
    }
    
    func test___when_client_log_disabled___logs_not_streamed_to_client() {
        queueLogStreamingModes = QueueLogStreamingModes(streamsToClient: false, streamsToLocalLog: true)
        
        logEntry = logEntry.with(
            appendedCoordinate: .bucketId(bucketId)
        )
        
        streamer.stream(logEntry: logEntry)
        
        assert {
            localLogStreamer.logEntries()
        } equals: {
            [logEntry]
        }
        
        assertTrue {
            clientSpecificLogStreamerProvider.perBucketStreamers[bucketId] == nil
        }
    }
}
