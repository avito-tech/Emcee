import AtomicModels
import EventBus
import Foundation
import Logging
import Models
import RunnerModels

public final class EventBusReportingTestRunnerStream: TestRunnerStream {
    private let entriesToRun: [TestEntry]
    private let eventBus: EventBus
    private let testContext: TestContext
    
    public init(
        entriesToRun: [TestEntry],
        eventBus: EventBus,
        testContext: TestContext
    ) {
        self.entriesToRun = entriesToRun
        self.eventBus = eventBus
        self.testContext = testContext
    }
    
    public func caughtException(testException: TestException) {}
    
    public func testStarted(testName: TestName) {
        guard let testEntry = testEntryFor(testName: testName) else {
            return Logger.warning("Can't find test entry for test \(testName)")
        }
        
        eventBus.post(
            event: .runnerEvent(.testStarted(testEntry: testEntry, testContext: testContext))
        )
    }
    
    public func testStopped(testStoppedEvent: TestStoppedEvent) {
        guard let testEntry = testEntryFor(testName: testStoppedEvent.testName) else {
            return Logger.warning("Can't find test entry for test \(testStoppedEvent.testName)")
        }
        
        eventBus.post(
            event: .runnerEvent(.testFinished(testEntry: testEntry, succeeded: testStoppedEvent.succeeded, testContext: testContext))
        )
    }
    
    private func testEntryFor(testName: TestName) -> TestEntry? {
        return entriesToRun.first(where: { (testEntry: TestEntry) -> Bool in
            testEntry.testName == testName
        })
    }
}
