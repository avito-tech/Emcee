import Foundation
import Models

public struct ChromeTraceEvent: Encodable {
    public enum Phase: String, Encodable {
        case begin = "B"
        case finish = "E"
    }
    
    public enum Result: String, Encodable {
        case success = "good"
        case failure = "bad"
        case flaky = "yellow"
    }
    
    public let testName: TestName
    public let result: Result
    public let phase: Phase
    public let timestamp: TimeInterval
    public let host: String
    public let simulatorId: String

    public init(
        testName: TestName,
        result: Result,
        phase: Phase,
        timestamp: TimeInterval,
        host: String,
        simulatorId: String)
    {
        self.testName = testName
        self.result = result
        self.phase = phase
        self.timestamp = timestamp
        self.host = host
        self.simulatorId = simulatorId
    }
    
    private enum CodingKeys: String, CodingKey {
        case testName = "name"
        case phase = "ph"
        case timestamp = "ts"
        case result = "cname"
        /**
         * We group by host. Each host may have multiple simulators:
         *  host_name >
         *     sim1:    |--------test1-------|-------test3--------|
         *     sim2:              |----------test2-----------|--test4--|
         */
        case host = "pid"
        case simulatorId = "tid"
    }
}

public struct ChromeTrace: Encodable {
    public let traceEvents: [ChromeTraceEvent]
}

public final class ChromeTraceGenerator {
    private let testingResult: CombinedTestingResults
    
    public init(testingResult: CombinedTestingResults) {
        self.testingResult = testingResult
    }
    
    private lazy var chromeTrace: ChromeTrace = {
        var previouslyFailedTests = Set<TestName>()
        let resultForTest = { (testEntryResult: TestEntryResult) -> ChromeTraceEvent.Result in
            let testName = testEntryResult.testEntry.testName
            if !testEntryResult.succeeded {
                previouslyFailedTests.insert(testName)
                return ChromeTraceEvent.Result.failure
            } else if previouslyFailedTests.contains(testName) {
                return ChromeTraceEvent.Result.flaky
            } else {
                return ChromeTraceEvent.Result.success
            }
        }
        
        let events = testingResult.unfilteredResults.flatMap { (result: TestEntryResult) in
            createEventsForTest(testResult: result, result: resultForTest(result))
        }
        return ChromeTrace(traceEvents: events)
    }()
    
    private func createEventsForTest(
        testResult: TestEntryResult,
        result: ChromeTraceEvent.Result)
        -> [ChromeTraceEvent]
    {
        let testName = testResult.testEntry.testName
        return testResult.testRunResults.flatMap { testRunResult -> [ChromeTraceEvent] in
            let startEvent = ChromeTraceEvent(
                testName: testName,
                result: result,
                phase: ChromeTraceEvent.Phase.begin,
                timestamp: testRunResult.startTime * 1000 * 1000,
                host: testRunResult.hostName,
                simulatorId: testRunResult.simulatorId)
            let finishEvent = ChromeTraceEvent(
                testName: testName,
                result: result,
                phase: ChromeTraceEvent.Phase.finish,
                timestamp: testRunResult.finishTime * 1000 * 1000,
                host: testRunResult.hostName,
                simulatorId: testRunResult.simulatorId)
            return [startEvent, finishEvent]
        }
    }
    
    public func writeReport(path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let report = try encoder.encode(chromeTrace)
        try report.write(to: URL(fileURLWithPath: path), options: [.atomicWrite])
    }
}
