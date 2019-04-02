import Ansi
import Foundation
@testable import Logging
import XCTest

final class NSLogLikeLogEntryTextFormatterTests: XCTestCase {
    func test() {
        let entry = LogEntry(
            message: "message",
            color: ConsoleColor.boldYellow,
            subprocessInfo: SubprocessInfo(subprocessId: 42, subprocessName: "subproc"),
            timestamp: Date(timeIntervalSince1970: 42),
            verbosity: Verbosity.always
        )
        let text = NSLogLikeLogEntryTextFormatter().format(logEntry: entry)
        
        let expectedTimestamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: entry.timestamp)
        
        XCTAssertEqual(
            text,
            "[ALWAYS] \(expectedTimestamp) \(ProcessInfo.processInfo.processName)[\(ProcessInfo.processInfo.processIdentifier)] subproc[42]: message"
        )
    }
}

