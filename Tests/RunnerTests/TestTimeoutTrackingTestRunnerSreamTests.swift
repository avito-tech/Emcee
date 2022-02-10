import CommonTestModels
import DateProviderTestHelpers
import EmceeLogging
import Foundation
import Runner
import XCTest

final class TestTimeoutTrackingTestRunnerSreamTests: XCTestCase {
    lazy var testName = TestName(className: "class", methodName: "test")
    lazy var dateProvider = DateProviderFixture()
    
    func test___test_finished_in_time___does_not_invoke_timeout_call() {
        let timeoutCallInvoked = XCTestExpectation(description: "Test timeout detected")
        timeoutCallInvoked.isInverted = true
        
        let stream = TestTimeoutTrackingTestRunnerSream(
            dateProvider: dateProvider,
            detectedLongRunningTest: { _, _ in
                timeoutCallInvoked.fulfill()
            },
            logger: { .noOp },
            maximumTestDuration: 5,
            pollPeriod: .milliseconds(100)
        )
        
        stream.testStarted(testName: testName)
        stream.testStopped(testStoppedEvent: TestStoppedEvent(testName: testName, result: .success, testDuration: 1, testExceptions: [], logs: [], testStartTimestamp: 0))
        
        wait(for: [timeoutCallInvoked], timeout: 5)
    }
    
    func test___test_hang_test___invokes_timeout_call_only_once() {
        let timeoutCallInvoked = XCTestExpectation(description: "Test timeout detected only once")
        timeoutCallInvoked.isInverted = true
        timeoutCallInvoked.expectedFulfillmentCount = 2
        
        let stream = TestTimeoutTrackingTestRunnerSream(
            dateProvider: dateProvider,
            detectedLongRunningTest: { _, _ in
                timeoutCallInvoked.fulfill()
            },
            logger: { .noOp },
            maximumTestDuration: 1,
            pollPeriod: .milliseconds(100)
        )
        
        stream.testStarted(testName: testName)
        dateProvider.result += 100
        
        wait(for: [timeoutCallInvoked], timeout: 5)
    }
    
    func test___test_hang_test_is_not_invoked___when_stream_closes() {
        let timeoutCallInvoked = XCTestExpectation(description: "Test timeout shouldn't be called when stream closes")
        timeoutCallInvoked.isInverted = true
        
        let stream = TestTimeoutTrackingTestRunnerSream(
            dateProvider: dateProvider,
            detectedLongRunningTest: { _, _ in
                timeoutCallInvoked.fulfill()
            },
            logger: { .noOp },
            maximumTestDuration: 1,
            pollPeriod: .milliseconds(100)
        )
        
        stream.testStarted(testName: testName)
        dateProvider.result += 100
        stream.closeStream()
        
        wait(for: [timeoutCallInvoked], timeout: 5)
    }
}
