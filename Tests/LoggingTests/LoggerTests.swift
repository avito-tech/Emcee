import Foundation
import EmceeLogging
import XCTest

final class LoggerTests: XCTestCase {
    func test___logger_uses_global_config() {
        let handler = FakeLoggerHandle()
        GlobalLoggerConfig.loggerHandler = handler
        
        let logEntry = LogEntry(
            file: "file",
            line: 42,
            coordinates: [],
            message: "message",
            timestamp: Date(),
            verbosity: .error
        )
        Logger.log(logEntry)
        XCTAssertEqual(handler.logEntries, [logEntry])
    }
}
