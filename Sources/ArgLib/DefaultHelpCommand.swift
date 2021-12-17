import Foundation

public final class DefaultHelpCommand: HelpCommand {
    private static let commandArgumentName = ArgumentName.doubleDashed(dashlessName: "command")
    
    public let name = "help"
    public let description = "Prints help"
    public let arguments: Arguments = [
        ArgumentDescription(
            name: DefaultHelpCommand.commandArgumentName,
            overview: "Name of a command to print its usage",
            optional: true
        )
    ]
    
    private let supportedCommands: [Command]
    private var supportedCommandsWithHelp: [Command] {
        return supportedCommands + [self]
    }

    public init(supportedCommands: [Command]) {
        self.supportedCommands = supportedCommands
    }
    
    public func run(payload: CommandPayload) throws {
        let commandNameToPrintUsageFor: String? = try payload.optionalSingleTypedValue(
            argumentName: DefaultHelpCommand.commandArgumentName
        )
        
        if let commandName = commandNameToPrintUsageFor {
            printUsage(commandName: commandName)
        } else {
            printGeneralUsage()
        }
    }
    
    public func payload(commandName: String?) -> CommandPayload {
        guard let commandName = commandName else {
            return CommandPayload(valueHolders: [])
            
        }
        return CommandPayload(
            valueHolders: [
                ArgumentValueHolder(argumentName: DefaultHelpCommand.commandArgumentName, stringValue: commandName)
            ]
        )
    }
    
    private func printUsage(commandName: String) {
        if let command = supportedCommandsWithHelp.first(where: { $0.name == commandName }) {
            printHelpLine("Command overview: \(command.description)")
            printHelpLine("Usage: \(ProcessInfo.processInfo.processName) \(commandName) <arguments>")
            if !command.arguments.argumentDescriptions.isEmpty {
                printHelpLine("Command arguments:")
            }
            for commandArgumentDescription in command.arguments.argumentDescriptions {
                printHelpLine(
                    usage(argumentDescription: commandArgumentDescription, allArgumentDescriptions: Array(command.arguments.argumentDescriptions))
                )
            }
        } else {
            printHelpLine("This program does not support '\(commandName)' command")
            printGeneralUsage()
        }
    }
    
    private func printGeneralUsage() {
        if supportedCommands.isEmpty {
            printHelpLine("This program does not have any commands")
        } else {
            printHelpLine("Usage: \(ProcessInfo.processInfo.processName) <command> <arguments>")
            printHelpLine("Supported commands:")
            for command in supportedCommandsWithHelp {
                let alignedCommandName = command.name.alignedToMatchWidth(otherStrings: supportedCommandsWithHelp.map { $0.name })
                printHelpLine(" * \(alignedCommandName)    \(command.description)")
            }
        }
    }
    
    private func usage(
        argumentDescription: ArgumentDescription,
        allArgumentDescriptions: [ArgumentDescription]
    ) -> String {
        var usage = " * \(argumentDescription.name.expectedInputValue.alignedToMatchWidth(otherStrings: allArgumentDescriptions.map { $0.name.expectedInputValue }))    \(argumentDescription.overview)"
        if usage.last != "." { usage += "." }
        if argumentDescription.multiple {
            usage += " This argument may be repeated multiple times."
        }
        if argumentDescription.optional {
            usage += " Optional."
        } else {
            usage += " Required."
        }
        return usage
    }
    
    private func printHelpLine(_ text: String) {
        var text = text
        if !text.hasSuffix("\n") {
            text = text + "\n"
        }
        let outputHandle = FileHandle.standardError
        outputHandle.write(Data(text.utf8))
    }
}

private extension String {
    func alignedToMatchWidth(otherStrings: [String]) -> String {
        let maximumLength = otherStrings.max { $0.count < $1.count }?.count ?? count
        return self + Array(repeating: " ", count: maximumLength - count).joined(separator: "")
    }
}
