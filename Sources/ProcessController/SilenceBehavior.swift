import Foundation

public class SilenceBehavior: CustomStringConvertible {
    public typealias Handler = (ProcessController) -> ()
    
    public enum Action: CustomStringConvertible {
        case noAutomaticAction
        case terminateAndForceKill
        case interruptAndForceKill
        case handler(Handler)
        
        public var description: String {
            switch self {
            case .noAutomaticAction:
                return "no action"
            case .terminateAndForceKill:
                return "sigterm"
            case .interruptAndForceKill:
                return "sigint"
            case .handler:
                return "custom handler"
            }
        }
    }
    
    public let automaticAction: Action
    public let allowedSilenceDuration: TimeInterval
    public let allowedTimeToConsumeStdin: TimeInterval
    
    public init(
        automaticAction: Action,
        allowedSilenceDuration: TimeInterval,
        allowedTimeToConsumeStdin: TimeInterval = 30
    ) {
        self.automaticAction = automaticAction
        self.allowedSilenceDuration = allowedSilenceDuration
        self.allowedTimeToConsumeStdin = allowedTimeToConsumeStdin
    }
    
    public var description: String {
        return "<\(type(of: self)) action: \(automaticAction), max silence: \(allowedSilenceDuration), stdin timeout: \(allowedTimeToConsumeStdin)>"
    }
}
