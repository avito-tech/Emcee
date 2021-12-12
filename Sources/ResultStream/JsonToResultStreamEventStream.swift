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
        logger.warning("Skipped xcresultstream event: array is an unexpected kind of root object")
    }
    
    public func newObject(_ object: NSDictionary, data: Data) {
        guard let name = object["name"] as? NSDictionary, let eventName = name["_value"] as? String else {
            return
        }
        
        do {
            switch eventName {
            case RSTestStarted.name.stringValue:
                let testStarted = try jsonDecoder.decode(RSTestStarted.self, from: data)
                do {
                    let testName = try testStarted.structuredPayload.testIdentifier.testName()
                    testRunnerStream.testStarted(testName: testName)
                } catch {
                    // when app crashes, test event contains not a test name, but a description of a crash
                    testRunnerStream.caughtException(
                        testException: TestException(
                            reason: testStarted.structuredPayload.testIdentifier.identifier.stringValue,
                            filePathInProject: "Unknown",
                            lineNumber: 0,
                            relatedTestName: nil
                        )
                    )
                }
            case RSTestFinished.name.stringValue:
                let testFinished = try jsonDecoder.decode(RSTestFinished.self, from: data)
                do {
                    let testStoppedEvent = try testFinished.testStoppedEvent(dateProvider: dateProvider)
                    testRunnerStream.testStopped(testStoppedEvent: testStoppedEvent)
                } catch {
                    // when app crashes, test event contains not a test name, but a description of a crash
                    testRunnerStream.caughtException(
                        testException: TestException(
                            reason: testFinished.structuredPayload.test.identifier.stringValue,
                            filePathInProject: "Unknown",
                            lineNumber: 0,
                            relatedTestName: nil
                        )
                    )
                }
            case RSIssueEmitted.name.stringValue:
                let issue = try jsonDecoder.decode(RSIssueEmitted.self, from: data)
                let testException = issue.structuredPayload.issue.testException()
                testRunnerStream.caughtException(testException: testException)
            case RSLogTextAppended.name.stringValue:
                let event = try jsonDecoder.decode(RSLogTextAppended.self, from: data)
                if let logText = event.structuredPayload.text {
                    testRunnerStream.logCaptured(entry: TestLogEntry(contents: logText.stringValue))
                }
            default:
                break
            }
        } catch {
            logger.error("Failed to parse result stream error for \(eventName) event: \(error)")
        }
    }
}
