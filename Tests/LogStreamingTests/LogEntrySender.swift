import EmceeLoggingModels
import EmceeLoggingTestHelpers
import Foundation
import LogStreaming
import RequestSender
import RequestSenderTestHelpers
import TestHelpers
import XCTest

final class LogEntrySenderTests: XCTestCase {
    private lazy var requestSender = FakeRequestSender()
    private lazy var logEntrySender = LogEntrySenderImpl(
        requestSender: requestSender
    )
    private lazy var logEntry = LogEntryFixture().logEntry()
    
    func test___successful_case() {
        requestSender.result = VoidPayload()
        
        let expectation = XCTestExpectation()
        
        logEntrySender.send(
            logEntry: logEntry,
            callbackQueue: DispatchQueue(label: "queue")
        ) { error in
            assertTrue { error == nil }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test___error() {
        requestSender.requestSenderError = .noData
        
        let expectation = XCTestExpectation()
        
        logEntrySender.send(
            logEntry: logEntry,
            callbackQueue: DispatchQueue(label: "queue")
        ) { error in
            assertNotNil {
                error
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
