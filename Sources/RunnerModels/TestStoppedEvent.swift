import Foundation
import EmceeTypes

public struct TestStoppedEvent: Equatable, CustomStringConvertible {
    public enum Result: String, Equatable {
        case success
        case failure
        case lost
    }
    
    public let testName: TestName
    public let result: Result
    public let testDuration: TimeInterval
    public private(set) var testExceptions: [TestException]
    public private(set) var logs: [TestLogEntry]
    public let testStartTimestamp: DateSince1970ReferenceDate
    
    public init(
        testName: TestName,
        result: Result,
        testDuration: TimeInterval,
        testExceptions: [TestException],
        logs: [TestLogEntry],
        testStartTimestamp: DateSince1970ReferenceDate
    ) {
        self.testName = testName
        self.result = result
        self.testDuration = testDuration
        self.testExceptions = testExceptions
        self.logs = logs
        self.testStartTimestamp = testStartTimestamp
    }
    
    public mutating func add(testException: TestException) {
        testExceptions.append(testException)
    }
    
    public mutating func add(logEntry: TestLogEntry) {
        logs.append(logEntry)
    }
    
    public var succeeded: Bool {
        return result == .success
    }
    
    public var description: String {
        return "<\(type(of: self)) \(testName) result: \(result), duration: \(testDuration) sec, started at: \(testStartTimestamp)>"
    }
}
