import CommonTestModels
import DateProvider
import RunnerModels
import SimulatorPoolModels

public final class RunnerResultsPreparerImpl: RunnerResultsPreparer {
    private let dateProvider: DateProvider
    private let lostTestProcessingMode: LostTestProcessingMode
    private let hostname: String
    
    public init(
        dateProvider: DateProvider,
        lostTestProcessingMode: LostTestProcessingMode,
        hostname: String
    ) {
        self.dateProvider = dateProvider
        self.lostTestProcessingMode = lostTestProcessingMode
        self.hostname = hostname
    }

    public func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry],
        requestedEntriesToRun: [TestEntry],
        udid: UDID
    ) -> [TestEntryResult] {
        return requestedEntriesToRun.map { requestedEntryToRun in
            prepareResult(
                requestedEntryToRun: requestedEntryToRun,
                udid: udid,
                collectedTestStoppedEvents: collectedTestStoppedEvents,
                collectedTestExceptions: collectedTestExceptions,
                collectedLogs: collectedLogs
            )
        }
    }
    
    private func prepareResult(
        requestedEntryToRun: TestEntry,
        udid: UDID,
        collectedTestStoppedEvents: [TestStoppedEvent],
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry]
    ) -> TestEntryResult {
        let correspondingTestStoppedEvents = testStoppedEvents(
            testName: requestedEntryToRun.testName,
            collectedTestStoppedEvents: collectedTestStoppedEvents
        )
        return testEntryResultForFinishedTest(
            udid: udid,
            testEntry: requestedEntryToRun,
            testStoppedEvents: correspondingTestStoppedEvents,
            collectedTestExceptions: collectedTestExceptions,
            collectedLogs: collectedLogs
        )
    }
    
    private func testEntryResultForFinishedTest(
        udid: UDID,
        testEntry: TestEntry,
        testStoppedEvents: [TestStoppedEvent],
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry]
    ) -> TestEntryResult {
        if testStoppedEvents.isEmpty {
            switch lostTestProcessingMode {
            case .reportLost:
                return .lost(testEntry: testEntry)
            case .reportError:
                return resultForSingleTestThatDidNotRun(
                    udid: udid,
                    testEntry: testEntry,
                    collectedTestExceptions: collectedTestExceptions,
                    collectedLogs: collectedLogs
                )
            }
        }
        
        return TestEntryResult.withResults(
            testEntry: testEntry,
            testRunResults: testStoppedEvents.map { testStoppedEvent -> TestRunResult in
                TestRunResult(
                    succeeded: testStoppedEvent.succeeded,
                    exceptions: testStoppedEvent.testExceptions + collectedTestExceptions,
                    logs: testStoppedEvent.logs + collectedLogs,
                    duration: testStoppedEvent.testDuration,
                    startTime: testStoppedEvent.testStartTimestamp,
                    hostName: hostname,
                    udid: udid
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
    
    private func resultForSingleTestThatDidNotRun(
        udid: UDID,
        testEntry: TestEntry,
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry]
    ) -> TestEntryResult {
        return .withResult(
            testEntry: testEntry,
            testRunResult: TestRunResult(
                succeeded: false,
                exceptions: collectedTestExceptions + [RunnerConstants.testDidNotRun(testEntry.testName).testException],
                logs: collectedLogs,
                duration: 0,
                startTime: dateProvider.dateSince1970ReferenceDate(),
                hostName: hostname,
                udid: udid
            )
        )
    }
}
