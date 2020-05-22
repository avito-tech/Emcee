import Foundation

extension Int: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = Int(argumentValue) else {
            throw GenericParseError<Int>(argumentValue: argumentValue)
        }
        self = value
    }
}

extension UInt: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = UInt(argumentValue) else {
            throw GenericParseError<UInt>(argumentValue: argumentValue)
        }
        self = value
    }
}
