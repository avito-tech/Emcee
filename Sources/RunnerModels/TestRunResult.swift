import EmceeTypes
import Foundation
import SimulatorPoolModels

/// A result of a single test run.
public struct TestRunResult: Codable, CustomStringConvertible, Hashable {
    public let succeeded: Bool
    public let exceptions: [TestException]
    public let logs: [TestLogEntry]
    public let duration: TimeInterval
    public let startTime: DateSince1970ReferenceDate
    public let hostName: String
    public let udid: UDID

    public var finishTime: DateSince1970ReferenceDate {
        return startTime.addingTimeInterval(duration)
    }

    public init(
        succeeded: Bool,
        exceptions: [TestException],
        logs: [TestLogEntry],
        duration: TimeInterval,
        startTime: DateSince1970ReferenceDate,
        hostName: String,
        udid: UDID
    ) {
        self.succeeded = succeeded
        self.exceptions = exceptions
        self.logs = logs
        self.duration = duration
        self.startTime = startTime
        self.hostName = hostName
        self.udid = udid
    }
    
    public var description: String {
        var result: [String] = ["\(type(of: self)) \(succeeded ? "succeeded" : "failed")"]
        result += ["duration \(String(format: "%.3f", duration)) sec"]
        result += ["\(udid)"]
        if !exceptions.isEmpty {
            result += ["\(exceptions.count) exceptions"]
        }
        if !logs.isEmpty {
            result += ["\(logs.count) log entries"]
        }
        return "<\(result.joined(separator: ", "))>"
    }
}
