import CommonTestModels
import Foundation

public protocol TestRunnerStream {
    func openStream()
    func testStarted(testName: TestName)
    func caughtException(testException: TestException)
    func logCaptured(entry: TestLogEntry)
    func testStopped(testStoppedEvent: TestStoppedEvent)
    func closeStream()
}
