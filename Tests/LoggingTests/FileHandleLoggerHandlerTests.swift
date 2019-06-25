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
        supportsAnsiColors: false,
        fileHandleShouldBeClosed: true
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
    
    func test___non_closable_file___is_not_closed() throws {
        let fileHandler = FakeFileHandle()
        let loggerHandler = FileHandleLoggerHandler(
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            supportsAnsiColors: false,
            fileHandleShouldBeClosed: false
        )
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertFalse(fileHandler.isClosed)
    }
    
    func test___closable_file___is_closed() throws {
        let fileHandler = FakeFileHandle()
        let loggerHandler = FileHandleLoggerHandler(
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            supportsAnsiColors: false,
            fileHandleShouldBeClosed: true
        )
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertTrue(fileHandler.isClosed)
    }
    
    func test___closable_file___is_closed_only_once() throws {
        let fileHandler = FakeFileHandle()
        let loggerHandler = FileHandleLoggerHandler(
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            supportsAnsiColors: false,
            fileHandleShouldBeClosed: true
        )
        loggerHandler.tearDownLogging(timeout: 10)
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertEqual(fileHandler.closeCounter, 1)
    }
    
    private func tempFileContents() throws -> String {
        return try String(contentsOfFile: tempFile.path.asString)
    }
}

