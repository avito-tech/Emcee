import Foundation
import SPMUtility
import Basic
import Logging

public struct CommandRegistry {
    private let parser: ArgumentParser
    private var commands: [Command] = []
    
    public init(usage: String, overview: String) {
        parser = ArgumentParser(usage: usage, overview: overview)
    }
    
    public mutating func register(command: Command.Type) {
        commands.append(command.init(parser: parser))
    }
    
    public func run(onDeterminedCommand: (Command) -> ()) throws {
        let parsedArguments = try parse()
        try process(arguments: parsedArguments, onDeterminedCommand: onDeterminedCommand)
    }
    
    private func parse() throws -> ArgumentParser.Result {
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        return try parser.parse(arguments)
    }
    
    private func process(arguments: ArgumentParser.Result, onDeterminedCommand: (Command) -> ()) throws {
        guard let subparser = arguments.subparser(parser),
            let command = commands.first(where: { $0.command == subparser }) else {
                let stream = BufferedOutputByteStream()
                parser.printUsage(on: stream)
                guard let description = stream.bytes.validDescription else {
                    Logger.fatal("Unable to generate description of usage")
                }
                throw CommandExecutionError.incorrectUsage(usageDescription: description)
        }
        onDeterminedCommand(command)
        try command.run(with: arguments)
    }
}
