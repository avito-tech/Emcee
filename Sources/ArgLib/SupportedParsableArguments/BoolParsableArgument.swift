import Foundation

extension Bool: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = Bool(argumentValue) else {
            throw GenericParseError<Int>(argumentValue: argumentValue)
        }
        self = value
    }
}
