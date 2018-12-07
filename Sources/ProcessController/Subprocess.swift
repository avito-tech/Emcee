import Foundation

public class Subprocess: CustomStringConvertible {
    public let arguments: [SubprocessArgument]
    public let environment: [String: String]
    public let maximumAllowedSilenceDuration: TimeInterval
    public let allowedTimeToConsumeStdin: TimeInterval
    public let stdoutContentsFile: String?
    public let stderrContentsFile: String?
    public let stdinContentsFile: String?

    public init(
        arguments: [SubprocessArgument],
        environment: [String: String] = [:],
        maximumAllowedSilenceDuration: TimeInterval = 0,
        allowedTimeToConsumeStdin: TimeInterval = 30,
        stdoutContentsFile: String? = nil,
        stderrContentsFile: String? = nil,
        stdinContentsFile: String? = nil)
    {
        self.arguments = arguments
        self.environment = environment
        self.maximumAllowedSilenceDuration = maximumAllowedSilenceDuration
        self.allowedTimeToConsumeStdin = allowedTimeToConsumeStdin
        self.stdoutContentsFile = stdoutContentsFile
        self.stderrContentsFile = stderrContentsFile
        self.stdinContentsFile = stdinContentsFile
    }
    
    public var description: String {
        return "<\(type(of: self)) args: \(arguments)>"
    }
}
