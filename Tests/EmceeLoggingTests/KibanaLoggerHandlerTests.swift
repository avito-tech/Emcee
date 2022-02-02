import EmceeLogging
import EmceeLoggingModels
import Foundation
import Kibana
import TestHelpers
import XCTest

final class KibanaLoggerHandlerTests: XCTestCase {
    lazy var kibanaClient = FakeKibanaClient()
    lazy var handler = KibanaLoggerHandler(kibanaClient: kibanaClient)
    
    func test___via_log_entry() {
        handler.handle(
            logEntry: LogEntry(
                file: "file",
                line: 42,
                coordinates: [
                    LogEntryCoordinate(name: "some", value: "data"),
                    LogEntryCoordinate(name: "withoutValue"),
                ],
                message: "hello",
                timestamp: Date(),
                verbosity: .info
            )
        )
        
        let event = kibanaClient.capturedEvents[0]
        
        assertTrue { event.level == "info" }
        assertTrue { event.message == "hello" }
        assert {
            event.metadata
        } equals: {
            [
                "some": "data",
                "withoutValue": "null",
                "fileLine": "file:42",
            ]
        }
    }
    
    func test___waits_for_completions_after_tear_down() {
        handler.handle(
            logEntry: LogEntry(
                file: "file",
                line: 42,
                coordinates: [
                    LogEntryCoordinate(name: "some", value: "data"),
                    LogEntryCoordinate(name: "withoutValue"),
                ],
                message: "hello",
                timestamp: Date(),
                verbosity: .info
            )
        )
        
        let event = kibanaClient.capturedEvents[0]
        
        let completionInvoked = XCTestExpectation(description: "")
        
        let impactQueue = DispatchQueue(label: "impactQueue")
        impactQueue.asyncAfter(deadline: .now() + 0.05) {
            event.completion(nil)
            completionInvoked.fulfill()
        }
        
        handler.tearDownLogging(timeout: 15)
        wait(for: [completionInvoked], timeout: 0)
    }
}

