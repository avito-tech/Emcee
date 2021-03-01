import Foundation
@testable import EmceeLogging
import XCTest

final class NSLogLikeLogEntryTextFormatterTests: XCTestCase {
    func test() {
        let entry = LogEntry(
            file: "file",
            line: 42,
            coordinates: [
                "some",
                "coordinates",
            ],
            message: "message",
            timestamp: Date(),
            verbosity: .always
        )
        let text = NSLogLikeLogEntryTextFormatter().format(logEntry: entry)
        
        let expectedTimestamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: entry.timestamp)
        
        XCTAssertEqual(
            text,
            "[ALWAYS] \(expectedTimestamp) file:42 some coordinates: message"
        )
    }
}

