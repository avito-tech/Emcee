import Foundation

public final class NoOpHelpCommand: HelpCommand {
    public let name = "help"
    public let description = "No help is provided"
    public let arguments: Arguments = []
    
    public func run(payload: CommandPayload) throws {}
}
