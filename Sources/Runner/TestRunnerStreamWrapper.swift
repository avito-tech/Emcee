import Foundation
import RunnerModels

final class TestRunnerStreamWrapper: TestRunnerStream {
    private let onOpenStream: () -> ()
    private let onTestStarted: (TestName) -> ()
    private let onTestException: (TestException) -> ()
    private let onLog: (TestLogEntry) -> ()
    private let onTestStopped: (TestStoppedEvent) -> ()
    private let onCloseStream: () -> ()
    
    init(
        onOpenStream: @escaping () -> (),
        onTestStarted: @escaping (TestName) -> (),
        onTestException: @escaping (TestException) -> (),
        onLog: @escaping (TestLogEntry) -> (),
        onTestStopped: @escaping (TestStoppedEvent) -> (),
        onCloseStream: @escaping () -> ()
    ) {
        self.onOpenStream = onOpenStream
        self.onTestStarted = onTestStarted
        self.onTestException = onTestException
        self.onLog = onLog
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
    
    func logCaptured(entry: TestLogEntry) {
        onLog(entry)
    }
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {
        onTestStopped(testStoppedEvent)
    }
    
    func closeStream() {
        onCloseStream()
    }
}
