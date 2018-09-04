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
    
    public let testName: String
    public let result: Result
    public let phase: Phase
    public let timestamp: TimeInterval
    public let host: String
    public let simulatorId: String

    public init(
        testName: String,
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
        var previouslyFailedTests = Set<String>()
        let resultForTest = { (testRunResult: TestRunResult) -> ChromeTraceEvent.Result in
            let testName = testRunResult.testEntry.testName
            if !testRunResult.succeeded {
                previouslyFailedTests.insert(testName)
                return ChromeTraceEvent.Result.failure
            } else if previouslyFailedTests.contains(testName) {
                return ChromeTraceEvent.Result.flaky
            } else {
                return ChromeTraceEvent.Result.success
            }
        }
        
        let events = testingResult.unfilteredTestRuns.flatMap { (testRunResult: TestRunResult) in
            createBeginAndEndEventsForTest(testRunResult: testRunResult, result: resultForTest(testRunResult))
        }
        return ChromeTrace(traceEvents: events)
    }()
    
    private func createBeginAndEndEventsForTest(testRunResult: TestRunResult, result: ChromeTraceEvent.Result) -> [ChromeTraceEvent] {
        let testName = testRunResult.testEntry.testName
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
    
    public func writeReport(path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let report = try encoder.encode(chromeTrace)
        try report.write(to: URL(fileURLWithPath: path), options: [.atomicWrite])
    }
}
