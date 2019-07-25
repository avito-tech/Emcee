import Foundation
import PathLib

public class Subprocess: CustomStringConvertible {    
    public let arguments: [SubprocessArgument]
    public let environment: [String: String]
    public let silenceBehavior: SilenceBehavior
    public let standardStreamsCaptureConfig: StandardStreamsCaptureConfig
    public let workingDirectory: AbsolutePath
    
    public init(
        arguments: [SubprocessArgument],
        environment: [String: String] = [:],
        silenceBehavior: SilenceBehavior = SilenceBehavior(
            automaticAction: .noAutomaticAction,
            allowedSilenceDuration: 0.0,
            allowedTimeToConsumeStdin: 30
        ),
        standardStreamsCaptureConfig: StandardStreamsCaptureConfig = StandardStreamsCaptureConfig(),
        workingDirectory: AbsolutePath = FileManager.default.currentAbsolutePath
    ) {
        self.arguments = arguments
        self.environment = environment
        self.silenceBehavior = silenceBehavior
        self.standardStreamsCaptureConfig = standardStreamsCaptureConfig
        self.workingDirectory = workingDirectory
    }
    
    public var description: String {
        return "<\(type(of: self)) args: \(arguments)>"
    }
}
