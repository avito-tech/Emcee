import Foundation

public final class TestStoppedEvent {
    public enum Result: String, Equatable {
        case success
        case failure
        case lost
    }
    
    public let testName: TestName
    public let result: Result
    public let duration: TimeInterval
    
    public init(
        testName: TestName,
        result: Result,
        duration: TimeInterval
    ) {
        self.testName = testName
        self.result = result
        self.duration = duration
    }
    
    public var succeeded: Bool {
        return result == .success
    }
}
