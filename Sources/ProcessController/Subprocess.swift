import Foundation

public class Subprocess: CustomStringConvertible {    
    public let arguments: [SubprocessArgument]
    public let environment: [String: String]
    public let silenceBehavior: SilenceBehavior
    public let standardStreamsCaptureConfig: StandardStreamsCaptureConfig
    
    public init(
        arguments: [SubprocessArgument],
        environment: [String: String] = [:],
        silenceBehavior: SilenceBehavior = SilenceBehavior(
            automaticAction: .noAutomaticAction,
            allowedSilenceDuration: 0.0,
            allowedTimeToConsumeStdin: 30
        ),
        standardStreamsCaptureConfig: StandardStreamsCaptureConfig = StandardStreamsCaptureConfig()
    ) {
        self.arguments = arguments
        self.environment = environment
        self.silenceBehavior = silenceBehavior
        self.standardStreamsCaptureConfig = standardStreamsCaptureConfig
    }
    
    public var description: String {
        return "<\(type(of: self)) args: \(arguments)>"
    }
}
