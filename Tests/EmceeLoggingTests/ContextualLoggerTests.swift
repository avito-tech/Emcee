import Logging
import EmceeLogging
import EmceeLoggingTestHelpers
import Foundation
import Logging
import QueueModels
import XCTest

final class ContextualLoggerTests: XCTestCase {
    lazy var handler = FakeLoggerHandle()
    
    func test___basic_logging() {
        let logger = ContextualLogger(logger: Logging.Logger(label: "label", factory: { _ in handler }))
        logger.debug("hello")
        
        XCTAssertTrue(handler.logCalls.count == 1)
        XCTAssertTrue(handler.logCalls[0].message == "hello")
        XCTAssertEqual(handler.logCalls[0].metadata?.isEmpty, true)
    }
    
    func test___chained_logger_with_metadata() {
        let logger = ContextualLogger(logger: Logging.Logger(label: "label", factory: { _ in handler }))
            .withMetadata(key: "new", value: "metadata")
        logger.debug("hello")
        
        XCTAssertTrue(handler.logCalls.count == 1)
        XCTAssertEqual(handler.logCalls[0].metadata, ["new": "metadata"])
    }
    
    func test___chained_logger_with_overriden_metadata() {
        let logger = ContextualLogger(logger: Logging.Logger(label: "label", factory: { _ in handler }))
            .withMetadata(key: .workerId, value: "abc")
        
        logger.debug("workerId", workerId: WorkerId("workerId"))
        
        XCTAssertTrue(handler.logCalls.count == 1)
        XCTAssertEqual(handler.logCalls[0].metadata, ["workerId": "workerId"])
    }
}
