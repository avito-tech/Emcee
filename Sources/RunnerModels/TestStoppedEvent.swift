import Foundation

public final class TestStoppedEvent: Equatable, CustomStringConvertible {
    public enum Result: String, Equatable {
        case success
        case failure
        case lost
    }
    
    public let testName: TestName
    public let result: Result
    public let testDuration: TimeInterval
    public let testExceptions: [TestException]
    public let testStartTimestamp: TimeInterval
    
    public init(
        testName: TestName,
        result: Result,
        testDuration: TimeInterval,
        testExceptions: [TestException],
        testStartTimestamp: TimeInterval
    ) {
        self.testName = testName
        self.result = result
        self.testDuration = testDuration
        self.testExceptions = testExceptions
        self.testStartTimestamp = testStartTimestamp
    }
    
    public var succeeded: Bool {
        return result == .success
    }
    
    public var description: String {
        return "<\(type(of: self)) \(testName) result: \(result), duration: \(testDuration) sec, started at: \(testStartTimestamp)>"
    }
    
    public static func == (left: TestStoppedEvent, right: TestStoppedEvent) -> Bool {
        return left.testName == right.testName
            && left.result == right.result
            && fabs(left.testDuration - right.testDuration) < 0.01
            && left.testExceptions == right.testExceptions
            && fabs(left.testStartTimestamp - right.testStartTimestamp) < 0.01
    }
}
