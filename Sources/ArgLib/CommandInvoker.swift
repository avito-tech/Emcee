import Foundation

public final class CommandInvoker {
    private let commands: [Command]
    
    public init(commands: [Command]) {
        self.commands = commands
    }
    
    public func invokeSuitableCommand(arguments: [String] = CommandLine.commandArguments) throws {
        let command = try CommandParser.choose(commandFrom: commands)
        
        let valueHolders = try CommandParser.map(
            stringValues: arguments,
            to: command.arguments.argumentDescriptions
        )
        
        try command.run(valueHolders: valueHolders)
    }
}
