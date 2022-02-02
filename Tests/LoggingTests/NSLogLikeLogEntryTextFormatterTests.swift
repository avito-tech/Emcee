import Foundation
import EmceeLogging
import EmceeLoggingModels
import XCTest

final class NSLogLikeLogEntryTextFormatterTests: XCTestCase {
    func test() {
        let entry = LogEntry(
            file: "file",
            line: 42,
            coordinates: [
                LogEntryCoordinate(name: "some"),
                LogEntryCoordinate(name: "coordinate", value: "value"),
            ],
            message: "message",
            timestamp: Date(),
            verbosity: .always
        )
        let text = NSLogLikeLogEntryTextFormatter().format(logEntry: entry)
        
        let expectedTimestamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: entry.timestamp)
        
        XCTAssertEqual(
            text,
            "[ALWAYS] \(expectedTimestamp) file:42 some coordinate:value: message"
        )
    }
}

