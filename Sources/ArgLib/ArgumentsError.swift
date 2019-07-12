import Foundation

public enum ArgumentsError: Error, CustomStringConvertible {
    case argumentMissing(ArgumentName)
    case multipleValuesFound(ArgumentName, values: [String])
    
    public var description: String {
        switch self {
        case .argumentMissing(let argumentName):
            return "Argument is missing: \(argumentName)"
        case .multipleValuesFound(let argumentName, let values):
            return "Argument '\(argumentName.expectedInputValue)' expected to have a single value, but multiple values are provided: " + values.joined(separator: ",") + "."
        }
    }
}
