import Foundation

public class Subprocess: CustomStringConvertible {    
    public let arguments: [SubprocessArgument]
    public let environment: [String: String]
    public let silenceBehavior: SilenceBehavior
    public let stdoutContentsFile: String?
    public let stderrContentsFile: String?
    public let stdinContentsFile: String?

    public init(
        arguments: [SubprocessArgument],
        environment: [String: String] = [:],
        silenceBehavior: SilenceBehavior = SilenceBehavior(
            automaticAction: .noAutomaticAction,
            allowedSilenceDuration: 0.0,
            allowedTimeToConsumeStdin: 30
        ),
        stdoutContentsFile: String? = nil,
        stderrContentsFile: String? = nil,
        stdinContentsFile: String? = nil)
    {
        self.arguments = arguments
        self.environment = environment
        self.silenceBehavior = silenceBehavior
        self.stdoutContentsFile = stdoutContentsFile
        self.stderrContentsFile = stderrContentsFile
        self.stdinContentsFile = stdinContentsFile
    }
    
    public var description: String {
        return "<\(type(of: self)) args: \(arguments)>"
    }
}
