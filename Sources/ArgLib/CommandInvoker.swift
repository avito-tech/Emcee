import Foundation

public final class CommandInvoker {
    private let commands: [Command]
    private let helpCommandType: HelpCommandType
    
    public struct InvokableCommand {
        public let command: Command
        public let commandPayload: CommandPayload
        
        public func invoke() throws {
            try command.run(payload: commandPayload)
        }
    }
    
    public enum HelpCommandType {
        case missing
        case custom(HelpCommand)
        case generateAutomatically
    }
    
    public init(commands: [Command], helpCommandType: HelpCommandType) {
        self.commands = commands
        self.helpCommandType = helpCommandType
    }
    
    public func invokableCommand(
        arguments: [String] = CommandLine.meaningfulArguments
    ) throws -> InvokableCommand {
        let command: Command
        do {
            command = try CommandParser.choose(
                commandFrom: commands + [helpCommand],
                stringValues: arguments
            )
        } catch {
            try helpCommand.run(payload: CommandPayload(valueHolders: []))
            throw error
        }
        
        let valueHolders = try CommandParser.map(
            stringValues: Array(arguments.dropFirst()),
            to: command.arguments.argumentDescriptions
        )
        
        return InvokableCommand(
            command: command,
            commandPayload: CommandPayload(
                valueHolders: valueHolders
            )
        )
    }
    
    private var helpCommand: HelpCommand {
        switch helpCommandType {
        case .missing: return NoOpHelpCommand()
        case .custom(let command): return command
        case .generateAutomatically: return DefaultHelpCommand(supportedCommands: commands)
        }
    }
}

extension CommandInvoker {
    public func invokeSuitableCommand(
        arguments: [String] = CommandLine.meaningfulArguments
    ) throws {
        try invokableCommand(arguments: arguments).invoke()
    }
}
