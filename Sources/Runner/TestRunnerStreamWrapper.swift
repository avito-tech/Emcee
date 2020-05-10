import Foundation
import Models
import RunnerModels

final class TestRunnerStreamWrapper: TestRunnerStream {
    private let onTestStarted: (TestName) -> ()
    private let onTestException: (TestException) -> ()
    private let onTestStopped: (TestStoppedEvent) -> ()
    
    init(
        onTestStarted: @escaping (TestName) -> (),
        onTestException: @escaping (TestException) -> (),
        onTestStopped: @escaping (TestStoppedEvent) -> ()
    ) {
        self.onTestStarted = onTestStarted
        self.onTestException = onTestException
        self.onTestStopped = onTestStopped
    }
    
    func testStarted(testName: TestName) {
        onTestStarted(testName)
    }
    
    func caughtException(testException: TestException) {
        onTestException(testException)
    }
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {
        onTestStopped(testStoppedEvent)
    }
}
