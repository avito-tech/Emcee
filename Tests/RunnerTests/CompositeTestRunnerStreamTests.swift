import Foundation
import Runner
import RunnerModels
import RunnerTestHelpers
import XCTest

final class CompositeTestRunnerStreamTests: XCTestCase {
    lazy var testRunnerStreams = [
        AccumulatingTestRunnerStream(),
        AccumulatingTestRunnerStream(),
    ]
    lazy var stream = CompositeTestRunnerStream(testRunnerStreams: testRunnerStreams)
    
    func test___delegating_stream_open() {
        for delegateStream in testRunnerStreams {
            delegateStream.streamIsOpen = false
        }
        
        stream.openStream()
        
        for delegateStream in testRunnerStreams {
            XCTAssertTrue(delegateStream.streamIsOpen)
        }
    }
    
    func test___delegating_test_started() {
        stream.testStarted(testName: testName)
        
        for delegateStream in testRunnerStreams {
            XCTAssertEqual(delegateStream.castTo(TestName.self, index: 0), testName)
        }
    }
    
    func test___delegating_test_exception() {
        stream.caughtException(testException: testException)
        
        for delegateStream in testRunnerStreams {
            XCTAssertEqual(delegateStream.castTo(TestException.self, index: 0), testException)
        }
    }
    
    func test___delegating_test_stopped() {
        stream.testStopped(testStoppedEvent: testStoppedEvent)
        
        for delegateStream in testRunnerStreams {
            XCTAssertEqual(delegateStream.castTo(TestStoppedEvent.self, index: 0), testStoppedEvent)
        }
    }
    
    func test___delegating_stream_close() {
        for delegateStream in testRunnerStreams {
            delegateStream.streamIsOpen = true
        }
        
        stream.closeStream()
        
        for delegateStream in testRunnerStreams {
            XCTAssertFalse(delegateStream.streamIsOpen)
        }
    }
    
    lazy var testException = TestException(reason: "reason", filePathInProject: "file", lineNumber: 42, relatedTestName: nil)
    lazy var testName = TestName(className: "class", methodName: "test")
    lazy var testStoppedEvent = TestStoppedEvent(
        testName: testName,
        result: .failure,
        testDuration: 22,
        testExceptions: [testException],
        logs: [],
        testStartTimestamp: 11
    )
}
