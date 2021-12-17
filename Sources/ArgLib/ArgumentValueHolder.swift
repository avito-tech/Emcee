import Foundation

public final class ArgumentValueHolder: Equatable, CustomStringConvertible {
    public let argumentName: ArgumentName
    public let stringValue: String
    
    public init(
        argumentName: ArgumentName,
        stringValue: String
    ) {
        self.argumentName = argumentName
        self.stringValue = stringValue
    }
    
    public var description: String {
        return "'\(argumentName.expectedInputValue)' = '\(stringValue)'"
    }
    
    public func typedValue<T>() throws -> T where T: ParsableArgument {
        return try T(argumentValue: stringValue)
    }
    
    public static func == (left: ArgumentValueHolder, right: ArgumentValueHolder) -> Bool {
        return left.argumentName == right.argumentName
            && left.stringValue == right.stringValue
    }
}
