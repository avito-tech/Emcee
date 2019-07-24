import Foundation
import Models

public protocol TestRunnerStream {
    func testStarted(testName: TestName)
    func testStopped(testStoppedEvent: TestStoppedEvent)
}
