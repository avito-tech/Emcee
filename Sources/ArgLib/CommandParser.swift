import Foundation
import OrderedSet

public final class CommandParser {
    
    public static func choose(
        commandFrom commands: [Command],
        stringValues: [String] = CommandLine.meaningfulArguments
    ) throws -> Command {
        guard let commandName = stringValues.first else {
            throw CommandParserError.noCommandProvided
        }
        guard let command = commands.first(where: { $0.name == commandName }) else {
            throw CommandParserError.unknownCommand(name: commandName)
        }
        return command
    }
    
    public static func map(
        stringValues: [String],
        to commandArguments: OrderedSet<ArgumentDescription>
    ) throws -> [ArgumentValueHolder] {
        var stringValues = stringValues
        
        let result = try commandArguments.compactMap { argumentDescription -> ArgumentValueHolder? in
            guard let index = stringValues.firstIndex(of: argumentDescription.name.expectedInputValue) else {
                if argumentDescription.optional {
                    return nil
                }
                throw CommandParserError.expectedArgument(argumentDescription.name)
            }
            
            guard index + 1 < stringValues.count else {
                throw CommandParserError.missingArgumentValue(argumentDescription.name)
            }
            
            let stringValue = stringValues.remove(at: index + 1)
            stringValues.remove(at: index)
            
            return ArgumentValueHolder(
                argumentName: argumentDescription.name,
                stringValue: stringValue
            )
        }
        
        if !stringValues.isEmpty {
            throw CommandParserError.unexpectedValues(stringValues)
        }
        
        return result
    }
}
