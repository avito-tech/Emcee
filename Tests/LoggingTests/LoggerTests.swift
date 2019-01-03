import Foundation
import Logging
import XCTest

final class LoggerTests: XCTestCase {
    func test___logger_uses_global_config() {
        let handler = FakeLoggerHandle()
        GlobalLoggerConfig.loggerHandler = handler
        
        let logEntry = LogEntry(
            message: "message",
            verbosity: Verbosity.error
        )
        Logger.log(logEntry)
        XCTAssertEqual(handler.logEntries, [logEntry])
    }
}

