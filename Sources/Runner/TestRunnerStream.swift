import Foundation
import Models
import RunnerModels

public protocol TestRunnerStream {
    func testStarted(testName: TestName)
    func testStopped(testStoppedEvent: TestStoppedEvent)
}
