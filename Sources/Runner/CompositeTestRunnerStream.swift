import AtomicModels
import Foundation
import RunnerModels

public final class CompositeTestRunnerStream: TestRunnerStream {
    private let testRunnerStreams: [TestRunnerStream]
    
    public init(testRunnerStreams: [TestRunnerStream]) {
        self.testRunnerStreams = testRunnerStreams
    }
    
    public func openStream() {
        testRunnerStreams.forEach { $0.openStream() }
    }
    
    public func caughtException(testException: TestException) {
        testRunnerStreams.forEach { $0.caughtException(testException: testException) }
    }
    
    public func testStarted(testName: TestName) {
        testRunnerStreams.forEach { $0.testStarted(testName: testName) }
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        testRunnerStreams.forEach { $0.testStopped(testStoppedEvent: testStoppedEvent) }
    }
    
    public func closeStream() {
        testRunnerStreams.forEach { $0.closeStream() }
    }
}
