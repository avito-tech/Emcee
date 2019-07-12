import Foundation

public enum CommandParserError: Error, CustomStringConvertible {
    case expectedArgument(ArgumentName)
    case missingArgumentValue(ArgumentName)
    case unexpectedValues([String])
    case noCommandProvided
    case unknownCommand(name: String)
    
    public var description: String {
        switch self {
        case .expectedArgument(let argumentName):
            return "Missing argument: " + argumentName.expectedInputValue
        case .missingArgumentValue(let argumentName):
            return "Expected to have a value next to " + argumentName.expectedInputValue
        case .unexpectedValues(let values):
            return "Unexpected or unmatched values: \(values)"
        case .noCommandProvided:
            return "No command provided."
        case .unknownCommand(let name):
            return "Unrecognized command: \(name)"
        }
    }
}
