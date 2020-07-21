import DateProvider
import Foundation
import Runner
import RunnerModels

public final class RegexLogParser: XcodebuildLogParser {
    private let dateProvider: DateProvider
    private let testStartedExpression: NSRegularExpression
    private let testExceptionExpression: NSRegularExpression
    private let testStoppedExpression: NSRegularExpression
    
    public enum ParseError: Error, CustomStringConvertible {
        case failedToParseTestDuration(value: String, input: String)
        case failedToParseXcodebuildTestResult(value: String, input: String)
        case failedToParseLineNumber(value: String, input: String)
        
        public var description: String {
            switch self {
            case .failedToParseTestDuration(let value, let input):
                return "Failed to parse test duration. Found unparsable value: '\(value)' in input '\(input)'"
            case .failedToParseXcodebuildTestResult(let value, let input):
                return "Failed to parse test result. Found unparsable value: '\(value)' in input '\(input)'"
            case .failedToParseLineNumber(let value, let input):
                return "Failed to parse line number. Found unparsable value: '\(value)' in input '\(input)'"
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
        testExceptionExpression = try NSRegularExpression(
            pattern: "^(.*):(\\d*): error: (-\\[.*\\]) : (.*)$",
            // Match groups: (/path:line)  (test name)   (reason)
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
        for line in string.split(separator: "\n", omittingEmptySubsequences: false) {
            let testNames = try attemptToParseStartTestEvent(string: String(line))
            testNames.forEach(testRunnerStream.testStarted)
            
            let testExceptions = try attemptToParseTestFailureEvent(string: String(line))
            testExceptions.forEach(testRunnerStream.caughtException)
            
            let testStoppedEvents = try attemptToParseTestStoppedEvent(string: String(line))
            testStoppedEvents.forEach(testRunnerStream.testStopped)
        }
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
    
    /// Attempts to parse a string into `TestException`.
    /// If string has format of `/path/to/file:line: error: -[ModuleWithTests.TestClassName testMethodName] : reason text`, it will then return `TestException` object.
    /// If the parser fails to parse class name and method name from the string, or if line number is not an integer, it will throw an exception.
    /// Otherwise it will return `nil`.
    /// - Parameter string: string to parse
    private func attemptToParseTestFailureEvent(string: String) throws -> [TestException] {
        let matches = testExceptionExpression.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        return try matches.map { match -> TestException in
            let filePath = (string as NSString).substring(with: match.range(at: 1))
            let lineNumberString = (string as NSString).substring(with: match.range(at: 2))
            guard let lineNumber = Int32(lineNumberString) else {
                throw ParseError.failedToParseLineNumber(value: lineNumberString, input: string)
            }
            _ = try TestName.parseObjCTestName(
                string: (string as NSString).substring(with: match.range(at: 3))
            )
            let reason = (string as NSString).substring(with: match.range(at: 4))
            return TestException(reason: reason, filePathInProject: filePath, lineNumber: lineNumber)
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
