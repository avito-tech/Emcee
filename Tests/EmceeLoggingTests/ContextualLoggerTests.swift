import DateProviderTestHelpers
import EmceeLogging
import EmceeLoggingModels
import EmceeLoggingTestHelpers
import Foundation
import QueueModels
import TestHelpers
import XCTest

final class ContextualLoggerTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture()
    lazy var loggerHandler = FakeLoggerHandle()
    lazy var logger = ContextualLogger(
        dateProvider: dateProvider,
        loggerHandler: loggerHandler,
        metadata: [:]
    )
    
    func test___basic_logging() {
        logger.debug("hello", file: "file", line: 42)
        
        assert {
            loggerHandler.logEntries
        } equals: {
            [
                LogEntry(
                    file: "file",
                    line: 42,
                    coordinates: [],
                    message: "hello",
                    timestamp: dateProvider.currentDate(),
                    verbosity: .debug
                )
            ]
        }
    }
    
    func test___chained_logger_with_metadata() {
        logger
            .withMetadata(key: "new", value: "metadata")
            .debug("hello", file: "file", line: 42)
        
        assert {
            loggerHandler.logEntries
        } equals: {
            [
                LogEntry(
                    file: "file",
                    line: 42,
                    coordinates: [
                        LogEntryCoordinate(name: "new", value: "metadata"),
                    ],
                    message: "hello",
                    timestamp: dateProvider.currentDate(),
                    verbosity: .debug
                )
            ]
        }
    }
    
    func test___chained_logger_with_overriden_metadata() {
        let logger = logger
            .withMetadata(key: .workerId, value: "oldValue")
            
        logger.debug("hello", workerId: "newValue", file: "file", line: 42)
        
        assert {
            loggerHandler.logEntries
        } equals: {
            [
                LogEntry(
                    file: "file",
                    line: 42,
                    coordinates: [
                        LogEntryCoordinate(name: "workerId", value: "newValue"),
                    ],
                    message: "hello",
                    timestamp: dateProvider.currentDate(),
                    verbosity: .debug
                )
            ]
        }
    }
}
