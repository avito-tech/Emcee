import ChromeTracing
import Foundation
import RunnerModels

public final class ChromeTraceGenerator {
    private let testingResult: CombinedTestingResults

    public init(testingResult: CombinedTestingResults) {
        self.testingResult = testingResult
    }

    private func createEventsForTest(
        testResult: TestEntryResult
    ) -> [ChromeTraceEvent] {
        let testName = testResult.testEntry.testName

        return testResult.testRunResults.map { testRunResult -> ChromeTraceEvent in
            return CompleteEvent(
                category: "test_run",
                name: testName.stringValue,
                timestamp: .seconds(testRunResult.startTime.timeIntervalSince1970),
                duration: .seconds(testRunResult.duration),
                processId: testRunResult.hostName,
                threadId: testRunResult.udid.value,
                color: testRunResult.succeeded ? .good : .bad
            )
        }
    }

    public func writeReport(path: String) throws {
        let events = testingResult.unfilteredResults.flatMap { (testResult: TestEntryResult) in
            createEventsForTest(testResult: testResult)
        }
        let chromeTrace = ChromeTrace(traceEvents: events)
        let report = try JSONEncoder.pretty().encode(chromeTrace)
        try report.write(to: URL(fileURLWithPath: path), options: [.atomicWrite])
    }
}
