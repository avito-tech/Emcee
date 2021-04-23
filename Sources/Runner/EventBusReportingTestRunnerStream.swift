import AtomicModels
import EventBus
import Foundation
import EmceeLogging
import RunnerModels

public final class EventBusReportingTestRunnerStream: TestRunnerStream {
    private let entriesToRun: [TestEntry]
    private let eventBus: EventBus
    private let logger: () -> ContextualLogger
    private let testContext: TestContext
    private let resultsProvider: () -> [TestEntryResult]
    
    public init(
        entriesToRun: [TestEntry],
        eventBus: EventBus,
        logger: @escaping () -> ContextualLogger,
        testContext: TestContext,
        resultsProvider: @escaping () -> [TestEntryResult]
    ) {
        self.entriesToRun = entriesToRun
        self.eventBus = eventBus
        self.logger = logger
        self.testContext = testContext
        self.resultsProvider = resultsProvider
    }
    
    public func openStream() {
        eventBus.post(
            event: .runnerEvent(.willRun(testEntries: entriesToRun, testContext: testContext))
        )
    }
    
    public func testStarted(testName: TestName) {
        guard let testEntry = testEntryFor(testName: testName) else {
            return logger().warning("Can't find test entry for test \(testName)")
        }
        
        eventBus.post(
            event: .runnerEvent(.testStarted(testEntry: testEntry, testContext: testContext))
        )
    }
    
    public func caughtException(testException: TestException) {}
    
    public func logCaptured(entry: TestLogEntry) {}
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        guard let testEntry = testEntryFor(testName: testStoppedEvent.testName) else {
            return logger().warning("Can't find test entry for test \(testStoppedEvent.testName)")
        }
        
        eventBus.post(
            event: .runnerEvent(.testFinished(testEntry: testEntry, succeeded: testStoppedEvent.succeeded, testContext: testContext))
        )
    }
    
    public func closeStream() {
        eventBus.post(
            event: .runnerEvent(.didRun(results: resultsProvider(), testContext: testContext))
        )
    }
    
    private func testEntryFor(testName: TestName) -> TestEntry? {
        return entriesToRun.first(where: { (testEntry: TestEntry) -> Bool in
            testEntry.testName == testName
        })
    }
}
