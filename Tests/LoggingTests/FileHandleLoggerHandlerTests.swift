import Basic
import Foundation
import Logging
import XCTest

final class FileHandleLoggerHandlerTests: XCTestCase {
    let tempFile = try! TemporaryFile(deleteOnClose: true)
    
    lazy var loggerHandler = FileHandleLoggerHandler(
        fileHandle: tempFile.fileHandle,
        verbosity: .info,
        logEntryTextFormatter: SimpleLogEntryTextFormatter(),
        supportsAnsiColors: false
    )
    
    func test___handling_higher_verbosity_entries___writes_to_file_handler() throws {
        let logEntry = LogEntry(
            message: "message",
            verbosity: Verbosity.always
        )
        loggerHandler.handle(logEntry: logEntry)
        
        XCTAssertEqual(
            try tempFileContents(),
            SimpleLogEntryTextFormatter().format(logEntry: logEntry) + "\n"
        )
    }
    
    func test___handling_same_verbosity_entries___writes_to_file_handler() throws {
        let logEntry = LogEntry(
            message: "message",
            verbosity: Verbosity.info
        )
        loggerHandler.handle(logEntry: logEntry)
        
        XCTAssertEqual(
            try tempFileContents(),
            SimpleLogEntryTextFormatter().format(logEntry: logEntry) + "\n"
        )
    }
    
    func test___handling_lower_verbosity_entries___does_not_write_to_file_handler() throws {
        let logEntry = LogEntry(
            message: "message",
            verbosity: Verbosity.debug
        )
        loggerHandler.handle(logEntry: logEntry)
        
        XCTAssertEqual(
            try tempFileContents(),
            ""
        )
    }
    
    private func tempFileContents() throws -> String {
        return try String(contentsOfFile: tempFile.path.pathString)
    }
}

