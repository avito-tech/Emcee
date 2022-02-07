import EmceeLoggingModels
import EmceeLoggingTestHelpers
import LogStreaming
import TestHelpers
import Foundation
import XCTest

final class LogEntryEndpointTests: XCTestCase {
    private lazy var streamer = InMemoryLogStreamer()
    private lazy var endpoint = LogEntryEndpoint(logStreamer: streamer)
    private lazy var logEntry = LogEntryFixture().logEntry()
    
    func test() throws {
        _ = try endpoint.handle(payload: logEntry)
        
        assert {
            streamer.logEntries()
        } equals: {
            [logEntry]
        }
    }
}
