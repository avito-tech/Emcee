import DateProviderTestHelpers
import EmceeLogging
import EmceeLoggingModels
import EmceeLoggingTestHelpers
import Foundation
import XCTest

final class AggregatedLoggerHandlerTests: XCTestCase {
    private lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 999))
    
    func test() {
        let handler1 = FakeLoggerHandle()
        let handler2 = FakeLoggerHandle()
        let aggregatedHandler = AggregatedLoggerHandler(
            handlers: [handler1, handler2]
        )
        
        let logEntry = LogEntry(
            file: "file",
            line: 42,
            coordinates: [],
            message: "",
            timestamp: dateProvider.currentDate(),
            verbosity: .always
        )
        aggregatedHandler.handle(logEntry: logEntry)
        
        XCTAssertEqual(handler1.logEntries, [logEntry])
        XCTAssertEqual(handler2.logEntries, [logEntry])
    }
}
