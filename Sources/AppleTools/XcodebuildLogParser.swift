import DateProvider
import Foundation
import Models
import Runner

public final class XcodebuildLogParser {
    private let dateProvider: DateProvider
    private let testStartedExpression: NSRegularExpression
    private let testStoppedExpression: NSRegularExpression
    
    public enum ParseError: Error, CustomStringConvertible {
        case failedToParseTestDuration(value: String, input: String)
        case failedToParseXcodebuildTestResult(value: String, input: String)
        
        public var description: String {
            switch self {
            case .failedToParseTestDuration(let value, let input):
                return "Failed to parse test duration. Found unparsable value: '\(value)' in input '\(input)'"
            case .failedToParseXcodebuildTestResult(let value, let input):
                return "Failed to parse test result. Found unparsable value: '\(value)' in input '\(input)'"
            }
        }
    }
    
    public enum XcodebuildTestResult: String, Equatable {
        case passed
        case failed
    }
    
    public init(
        dateProvider: DateProvider
    ) throws {
        self.dateProvider = dateProvider
        testStartedExpression = try NSRegularExpression(
            pattern: "^Test Case '(-\\[.*\\])' started\\.$",
            // Match groups:      (test name)
            options: [.anchorsMatchLines]
        )
        testStoppedExpression = try NSRegularExpression(
            pattern: "^Test Case '(-\\[.*\\])' (failed|passed) \\((\\d+.\\d+) seconds\\)\\.$",
            // Match groups:      (test name)  (test result)      (duration)
            options: [.anchorsMatchLines]
        )
    }
    
    public func parse(
        string: String,
        testRunnerStream: TestRunnerStream
    ) throws {
        let testNames = try attemptToParseStartTestEvent(string: string)
        testNames.forEach(testRunnerStream.testStarted)
        
        let testStoppedEvents = try attemptToParseTestStoppedEvent(string: string)
        testStoppedEvents.forEach(testRunnerStream.testStopped)
    }
    
    /// Attempts to parse a string into `TestName`.
    /// If string has format of `Test Case '-[ModuleWithTests.TestClassName testMethodName]' started.`, it will then return `TestName` object.
    /// It the parser fails to parse class name and method name from the string, it will throw an exception.
    /// Otherwise it will return `nil`.
    /// - Parameter string: string to parse
    private func attemptToParseStartTestEvent(string: String) throws -> [TestName] {
        let matches = testStartedExpression.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        return try matches.map { match -> TestName in
            let objcTestName = (string as NSString).substring(with: match.range(at: 1))
            return try TestName.parseObjCTestName(string: objcTestName)
        }
    }
    
    /// `Test Case '-[ModuleWithTests.TestClassName testMethodName]' passed (22.128 seconds).`
    /// - Parameter string: string to parse
    private func attemptToParseTestStoppedEvent(string: String) throws -> [TestStoppedEvent] {
        let matches = testStoppedExpression.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        return try matches.map { match -> TestStoppedEvent in
            let objcTestName = (string as NSString).substring(with: match.range(at: 1))
            let testName = try TestName.parseObjCTestName(string: objcTestName)
            
            let testResultValue = (string as NSString).substring(with: match.range(at: 2))
            guard let testResult = XcodebuildTestResult(rawValue: testResultValue) else {
                throw ParseError.failedToParseXcodebuildTestResult(value: testResultValue, input: string)
            }
            
            let testDurationValue = (string as NSString).substring(with: match.range(at: 3))
            guard let testDuration = TimeInterval(testDurationValue) else {
                throw ParseError.failedToParseTestDuration(value: testDurationValue, input: string)
            }
            
            return TestStoppedEvent(
                testName: testName,
                result: testResult == .passed ? .success : .failure,
                testDuration: testDuration,
                testExceptions: [],
                testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970 - testDuration
            )
        }
    }
}
