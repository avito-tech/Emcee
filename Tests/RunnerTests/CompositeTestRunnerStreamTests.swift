import Foundation
import Models
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
    
    lazy var testException = TestException(reason: "reason", filePathInProject: "file", lineNumber: 42)
    lazy var testName = TestName(className: "class", methodName: "test")
    lazy var testStoppedEvent = TestStoppedEvent(
        testName: testName,
        result: .failure,
        testDuration: 22,
        testExceptions: [testException],
        testStartTimestamp: 11
    )
}
