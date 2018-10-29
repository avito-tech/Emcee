import Foundation

/// A result of a single test run.
public struct TestRunResult: Codable, CustomStringConvertible {
    public let succeeded: Bool
    public let exceptions: [TestException]
    public let duration: TimeInterval
    public let startTime: TimeInterval
    public let finishTime: TimeInterval
    public let hostName: String
    public let processId: Int32
    public let simulatorId: String

    public init(
        succeeded: Bool,
        exceptions: [TestException],
        duration: TimeInterval,
        startTime: TimeInterval,
        finishTime: TimeInterval,
        hostName: String,
        processId: Int32,
        simulatorId: String)
    {
        self.succeeded = succeeded
        self.exceptions = exceptions
        self.duration = duration
        self.startTime = startTime
        self.finishTime = finishTime
        self.hostName = hostName
        self.processId = processId
        self.simulatorId = simulatorId
    }
    
    public var description: String {
        return "<\(type(of: self)) \(succeeded ? "success" : "failure")>"
    }
}
