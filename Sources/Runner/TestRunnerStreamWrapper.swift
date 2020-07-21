import Foundation
import RunnerModels

final class TestRunnerStreamWrapper: TestRunnerStream {
    private let onOpenStream: () -> ()
    private let onTestStarted: (TestName) -> ()
    private let onTestException: (TestException) -> ()
    private let onTestStopped: (TestStoppedEvent) -> ()
    private let onCloseStream: () -> ()
    
    init(
        onOpenStream: @escaping () -> (),
        onTestStarted: @escaping (TestName) -> (),
        onTestException: @escaping (TestException) -> (),
        onTestStopped: @escaping (TestStoppedEvent) -> (),
        onCloseStream: @escaping () -> ()
    ) {
        self.onOpenStream = onOpenStream
        self.onTestStarted = onTestStarted
        self.onTestException = onTestException
        self.onTestStopped = onTestStopped
        self.onCloseStream = onCloseStream
    }
    
    func openStream() {
        onOpenStream()
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
    
    func closeStream() {
        onCloseStream()
    }
}
