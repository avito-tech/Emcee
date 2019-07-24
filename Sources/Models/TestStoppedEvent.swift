import Foundation

public final class TestStoppedEvent {
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
}
