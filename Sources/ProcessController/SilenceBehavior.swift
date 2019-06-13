import Foundation

public class SilenceBehavior {
    public typealias Handler = (ProcessController) -> ()
    
    public enum Action {
        case noAutomaticAction
        case terminateAndForceKill
        case interruptAndForceKill
        case handler(Handler)
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
}
