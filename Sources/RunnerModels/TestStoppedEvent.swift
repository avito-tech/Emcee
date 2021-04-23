import Foundation

public struct TestStoppedEvent: Equatable, CustomStringConvertible {
    public enum Result: String, Equatable {
        case success
        case failure
        case lost
    }
    
    public let testName: TestName
    public let result: Result
    public let testDuration: TimeInterval
    public let testExceptions: [TestException]
    public let logs: [TestLogEntry]
    public let testStartTimestamp: TimeInterval
    
    public init(
        testName: TestName,
        result: Result,
        testDuration: TimeInterval,
        testExceptions: [TestException],
        logs: [TestLogEntry],
        testStartTimestamp: TimeInterval
    ) {
        self.testName = testName
        self.result = result
        self.testDuration = testDuration
        self.testExceptions = testExceptions
        self.logs = logs
        self.testStartTimestamp = testStartTimestamp
    }
    
    public var succeeded: Bool {
        return result == .success
    }
    
    public var description: String {
        return "<\(type(of: self)) \(testName) result: \(result), duration: \(testDuration) sec, started at: \(testStartTimestamp)>"
    }
}
