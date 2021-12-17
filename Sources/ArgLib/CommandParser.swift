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
        
        let result = try commandArguments.flatMap { argumentDescription -> [ArgumentValueHolder] in
            let indexes: [Int] = stringValues.enumerated().compactMap { (element: EnumeratedSequence<[String]>.Iterator.Element) -> Int? in
                if element.element == argumentDescription.name.expectedInputValue {
                    return element.offset
                }
                return nil
            }
            
            if indexes.isEmpty {
                if argumentDescription.optional {
                    return []
                }
                throw CommandParserError.expectedArgument(argumentDescription.name)
            }

            for index in indexes {
                guard index + 1 < stringValues.count else {
                    throw CommandParserError.missingArgumentValue(argumentDescription.name)
                }
            }

            return indexes.reversed().map { index -> ArgumentValueHolder in
                let stringValue = stringValues.remove(at: index + 1)
                stringValues.remove(at: index)
                
                return ArgumentValueHolder(
                    argumentName: argumentDescription.name,
                    stringValue: stringValue
                )
            }.reversed()
        }
        
        if !stringValues.isEmpty {
            throw CommandParserError.unexpectedValues(stringValues)
        }
        
        return result
    }
}
