import DateProviderTestHelpers
import Foundation
import EmceeLogging
import TestHelpers
import Tmp
import XCTest

final class FileHandleLoggerHandlerTests: XCTestCase {
    lazy var tempFile = assertDoesNotThrow { try TemporaryFile(deleteOnDealloc: true) }
    
    lazy var loggerHandler = FileHandleLoggerHandler(
        dateProvider: DateProviderFixture(),
        fileHandle: tempFile.fileHandleForWriting,
        verbosity: .info,
        logEntryTextFormatter: SimpleLogEntryTextFormatter(),
        fileHandleShouldBeClosed: true,
        skipMetadataFlag: nil
    )
    
    func test___handling_higher_verbosity_entries___writes_to_file_handler() throws {
        let logEntry = LogEntry(
            file: "file",
            line: 42,
            coordinates: [],
            message: "message",
            timestamp: Date(),
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
            file: "file",
            line: 42,
            coordinates: [],
            message: "message",
            timestamp: Date(),
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
            file: "file",
            line: 42,
            coordinates: [],
            message: "message",
            timestamp: Date(),
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
            dateProvider: DateProviderFixture(),
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            fileHandleShouldBeClosed: false,
            skipMetadataFlag: nil
        )
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertFalse(fileHandler.isClosed)
    }
    
    func test___closable_file___is_closed() throws {
        let fileHandler = FakeFileHandle()
        let loggerHandler = FileHandleLoggerHandler(
            dateProvider: DateProviderFixture(),
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            fileHandleShouldBeClosed: true,
            skipMetadataFlag: nil
        )
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertTrue(fileHandler.isClosed)
    }
    
    func test___closable_file___is_closed_only_once() throws {
        let fileHandler = FakeFileHandle()
        let loggerHandler = FileHandleLoggerHandler(
            dateProvider: DateProviderFixture(),
            fileHandle: fileHandler,
            verbosity: .always,
            logEntryTextFormatter: SimpleLogEntryTextFormatter(),
            fileHandleShouldBeClosed: true,
            skipMetadataFlag: nil
        )
        loggerHandler.tearDownLogging(timeout: 10)
        loggerHandler.tearDownLogging(timeout: 10)
        
        XCTAssertEqual(fileHandler.closeCounter, 1)
    }
    
    private func tempFileContents() throws -> String {
        return try String(contentsOf: tempFile.absolutePath.fileUrl)
    }
}

