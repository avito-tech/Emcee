import DateProvider
import Foundation
import EmceeLogging
import ResultStreamModels
import Runner
import RunnerModels
import JSONStream

public final class JsonToResultStreamEventStream: JSONReaderEventStream {
    private let jsonDecoder = JSONDecoder()
    private let logger: ContextualLogger
    private let testRunnerStream: TestRunnerStream
    private let dateProvider: DateProvider
    
    public init(
        dateProvider: DateProvider,
        logger: ContextualLogger,
        testRunnerStream: TestRunnerStream
    ) {
        self.dateProvider = dateProvider
        self.logger = logger
        self.testRunnerStream = testRunnerStream
    }
    
    public func newArray(_ array: NSArray, data: Data) {
        logger.debug("Skipped xcresultstream event: array is an unexpected kind of root object")
    }
    
    public func newObject(_ object: NSDictionary, data: Data) {
        guard let name = object["name"] as? NSDictionary, let eventName = name["_value"] as? String else {
            return
        }
        
        do {
            switch eventName {
            case RSTestStarted.name.stringValue:
                let testStarted = try jsonDecoder.decode(RSTestStarted.self, from: data)
                let testName = try testStarted.structuredPayload.testIdentifier.testName()
                testRunnerStream.testStarted(testName: testName)
            case RSTestFinished.name.stringValue:
                let testFinished = try jsonDecoder.decode(RSTestFinished.self, from: data)
                let testStoppedEvent = try testFinished.testStoppedEvent(dateProvider: dateProvider)
                testRunnerStream.testStopped(testStoppedEvent: testStoppedEvent)
            case RSIssueEmitted.name.stringValue:
                let issue = try jsonDecoder.decode(RSIssueEmitted.self, from: data)
                let testException = issue.structuredPayload.issue.testException()
                testRunnerStream.caughtException(testException: testException)
            default:
                break
            }
        } catch {
            logger.error("Failed to parse result stream error for \(eventName) event: \(error)")
        }
    }
}
