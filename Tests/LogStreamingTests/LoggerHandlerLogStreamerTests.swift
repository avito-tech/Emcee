import EmceeLogging
import EmceeLoggingTestHelpers
import Foundation
import LogStreaming
import TestHelpers
import XCTest

final class LoggerHandlerLogStreamerTests: XCTestCase {
    private lazy var loggerHandler = FakeLoggerHandle()
    private lazy var streamer = LoggerHandlerLogStreamer(
        loggerHandler: loggerHandler
    )
    private lazy var logEntry = LogEntryFixture().logEntry()
    
    func test() {
        streamer.stream(
            logEntry: logEntry
        )
        
        assert {
            loggerHandler.logEntries
        } equals: {
            [logEntry]
        }
    }
}
