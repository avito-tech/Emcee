import Foundation

public final class CommandInvoker {
    private let commands: [Command]
    
    public init(commands: [Command]) {
        self.commands = commands
    }
    
    public func invokeSuitableCommand(
        arguments: [String] = CommandLine.meaningfulArguments
    ) throws {
        let command = try CommandParser.choose(
            commandFrom: commands,
            stringValues: arguments
        )
        
        let valueHolders = try CommandParser.map(
            stringValues: Array(arguments.dropFirst()),
            to: command.arguments.argumentDescriptions
        )
        
        try command.run(
            payload: CommandPayload(
                valueHolders: valueHolders
            )
        )
    }
}
