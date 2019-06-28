import Foundation

public class IntArgumentDescription: ArgumentDescription {
    public typealias ValueType = Int
}

public struct IntParseError: Error, CustomStringConvertible {
    public let argumentValue: String
    
    public var description: String {
        return "Unable to convert \(argumentValue) into Int type"
    }
}

extension Int: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = Int(argumentValue) else {
            throw IntParseError(argumentValue: argumentValue)
        }
        self = value
    }
}
