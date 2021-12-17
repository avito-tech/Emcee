import Foundation

public protocol HelpCommand: Command {
    func payload(commandName: String?) -> CommandPayload
}
