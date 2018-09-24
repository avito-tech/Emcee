import Foundation

public class Subprocess: CustomStringConvertible {
    public let arguments: [String]
    public let environment: [String: String]
    public let maximumAllowedSilenceDuration: TimeInterval
    public let allowedTimeToConsumeStdin: TimeInterval
    public let stdoutContentsFile: String
    public let stderrContentsFile: String
    public let stdinContentsFile: String

    public init(
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        maximumAllowedSilenceDuration: TimeInterval = 0,
        allowedTimeToConsumeStdin: TimeInterval = 5,
        stdoutContentsFile: String? = nil,
        stderrContentsFile: String? = nil,
        stdinContentsFile: String? = nil)
    {
        self.arguments = arguments
        self.environment = environment
        self.maximumAllowedSilenceDuration = maximumAllowedSilenceDuration
        self.allowedTimeToConsumeStdin = allowedTimeToConsumeStdin
        
        let uuid = UUID().uuidString
        let executableName = arguments[0].lastPathComponent
        self.stdoutContentsFile = stdoutContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(executableName)_stdout.txt")
        self.stderrContentsFile = stderrContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(executableName)_stderr.txt")
        self.stdinContentsFile = stdinContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(executableName)_stdin.txt")
    }
    
    public var description: String {
        return "<\(type(of: self)) args: \(arguments)>"
    }
}
