import Foundation
import Models
import RunnerModels

public protocol TestRunnerStream {
    func openStream()
    func testStarted(testName: TestName)
    func caughtException(testException: TestException)
    func testStopped(testStoppedEvent: TestStoppedEvent)
    func closeStream()
}
