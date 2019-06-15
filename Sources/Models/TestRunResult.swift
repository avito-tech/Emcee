import Foundation

/// A result of a single test run.
public final class TestRunResult: Codable, CustomStringConvertible, Equatable {
    public let succeeded: Bool
    public let exceptions: [TestException]
    public let duration: TimeInterval
    public let startTime: TimeInterval
    public let finishTime: TimeInterval
    public let hostName: String
    public let simulatorId: String

    public init(
        succeeded: Bool,
        exceptions: [TestException],
        duration: TimeInterval,
        startTime: TimeInterval,
        finishTime: TimeInterval,
        hostName: String,
        simulatorId: String
        )
    {
        self.succeeded = succeeded
        self.exceptions = exceptions
        self.duration = duration
        self.startTime = startTime
        self.finishTime = finishTime
        self.hostName = hostName
        self.simulatorId = simulatorId
    }
    
    public var description: String {
        return "<\(type(of: self)) \(succeeded ? "success" : "failure")>"
    }

    public static func ==(left: TestRunResult, right: TestRunResult) -> Bool {
        return left.succeeded == right.succeeded
            && left.exceptions == right.exceptions
            && left.duration == right.duration
            && left.startTime == right.startTime
            && left.finishTime == right.finishTime
            && left.hostName == right.hostName
            && left.simulatorId == right.simulatorId
    }
}
