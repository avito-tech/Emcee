import Foundation
@testable import EmceeLogging
import XCTest

final class NSLogLikeLogEntryTextFormatterTests: XCTestCase {
    func test() {
        let entry = LogEntry(
            message: "message",
            pidInfo: PidInfo(pid: 42, name: "subproc"),
            timestamp: Date(timeIntervalSince1970: 42),
            verbosity: Verbosity.always
        )
        let text = NSLogLikeLogEntryTextFormatter().format(logEntry: entry)
        
        let expectedTimestamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: entry.timestamp)
        
        XCTAssertEqual(
            text,
            "[ALWAYS] \(expectedTimestamp) subproc[42]: message"
        )
    }
}

