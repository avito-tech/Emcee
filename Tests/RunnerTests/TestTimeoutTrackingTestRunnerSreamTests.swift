import DateProviderTestHelpers
import Foundation
import Models
import Runner
import RunnerModels
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
            maximumTestDuration: 5
        )
        
        stream.testStarted(testName: testName)
        stream.testStopped(testStoppedEvent: TestStoppedEvent(testName: testName, result: .success, testDuration: 1, testExceptions: [], testStartTimestamp: 0))
        
        wait(for: [timeoutCallInvoked], timeout: 5)
    }
    
    func test___test_hang_test___invokes_timeout_call() {
        let timeoutCallInvoked = XCTestExpectation(description: "Test timeout detected")
        
        let stream = TestTimeoutTrackingTestRunnerSream(
            dateProvider: dateProvider,
            detectedLongRunningTest: { _, _ in
                timeoutCallInvoked.fulfill()
            },
            maximumTestDuration: 5
        )
        
        stream.testStarted(testName: testName)
        dateProvider.result += 100
        
        wait(for: [timeoutCallInvoked], timeout: 15)
    }
}
