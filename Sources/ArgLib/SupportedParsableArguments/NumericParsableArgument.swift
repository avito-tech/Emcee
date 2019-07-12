import Foundation

public struct NumberParseError<T>: Error, CustomStringConvertible {
    public let argumentValue: String
    
    public init(argumentValue: String) {
        self.argumentValue = argumentValue
    }
    
    public var description: String {
        return "Unable to convert '\(argumentValue)' into \(T.self) type"
    }
}

extension Int: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = Int(argumentValue) else {
            throw NumberParseError<Int>(argumentValue: argumentValue)
        }
        self = value
    }
}

extension UInt: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = UInt(argumentValue) else {
            throw NumberParseError<UInt>(argumentValue: argumentValue)
        }
        self = value
    }
}
