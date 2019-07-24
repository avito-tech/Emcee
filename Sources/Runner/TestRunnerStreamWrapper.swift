import Foundation
import Models

final class TestRunnerStreamWrapper: TestRunnerStream {
    private let onTestStarted: (TestName) -> ()
    private let onTestStopped: (TestStoppedEvent) -> ()
    
    init(
        onTestStarted: @escaping (TestName) -> (),
        onTestStopped: @escaping (TestStoppedEvent) -> ()
    ) {
        self.onTestStarted = onTestStarted
        self.onTestStopped = onTestStopped
    }
    
    func testStarted(testName: TestName) {
        onTestStarted(testName)
    }
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {
        onTestStopped(testStoppedEvent)
    }
}
