import Foundation
import LocalHostDeterminer
import RunnerModels
import SimulatorPoolModels

public protocol RunnerResultsPreparer {
    func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        requestedEntriesToRun: [TestEntry],
        simulatorId: UDID
    ) -> [TestEntryResult]
}

public final class RunnerResultsPreparerImpl: RunnerResultsPreparer {
    public init() {}

    public func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        requestedEntriesToRun: [TestEntry],
        simulatorId: UDID
    ) -> [TestEntryResult] {
        return requestedEntriesToRun.map { requestedEntryToRun in
            prepareResult(
                requestedEntryToRun: requestedEntryToRun,
                simulatorId: simulatorId,
                collectedTestStoppedEvents: collectedTestStoppedEvents
            )
        }
    }
    
    private func prepareResult(
        requestedEntryToRun: TestEntry,
        simulatorId: UDID,
        collectedTestStoppedEvents: [TestStoppedEvent]
    ) -> TestEntryResult {
        let correspondingTestStoppedEvents = testStoppedEvents(
            testName: requestedEntryToRun.testName,
            collectedTestStoppedEvents: collectedTestStoppedEvents
        )
        return testEntryResultForFinishedTest(
            simulatorId: simulatorId,
            testEntry: requestedEntryToRun,
            testStoppedEvents: correspondingTestStoppedEvents
        )
    }
    
    private func testEntryResultForFinishedTest(
        simulatorId: UDID,
        testEntry: TestEntry,
        testStoppedEvents: [TestStoppedEvent]
    ) -> TestEntryResult {
        guard !testStoppedEvents.isEmpty else {
            return .lost(testEntry: testEntry)
        }
        return TestEntryResult.withResults(
            testEntry: testEntry,
            testRunResults: testStoppedEvents.map { testStoppedEvent -> TestRunResult in
                TestRunResult(
                    succeeded: testStoppedEvent.succeeded,
                    exceptions: testStoppedEvent.testExceptions,
                    duration: testStoppedEvent.testDuration,
                    startTime: testStoppedEvent.testStartTimestamp,
                    hostName: LocalHostDeterminer.currentHostAddress,
                    simulatorId: simulatorId
                )
            }
        )
    }
    
    private func testStoppedEvents(
        testName: TestName,
        collectedTestStoppedEvents: [TestStoppedEvent]
    ) -> [TestStoppedEvent] {
        return collectedTestStoppedEvents.filter { $0.testName == testName }
    }
}
