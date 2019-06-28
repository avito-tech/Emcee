import Foundation

public final class ArgumentValueHolder: Hashable {
    public let argumentDescription: ArgumentDescription
    public let stringValue: String
    
    public init(
        argumentDescription: ArgumentDescription,
        stringValue: String
    ) {
        self.argumentDescription = argumentDescription
        self.stringValue = stringValue
    }
    
    public func typedValue<T>() throws -> T where T: ParsableArgument {
        return try T(argumentValue: stringValue)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(argumentDescription)
        hasher.combine(stringValue)
    }
    
    public static func == (left: ArgumentValueHolder, right: ArgumentValueHolder) -> Bool {
        return left.argumentDescription == right.argumentDescription
            && left.stringValue == right.stringValue
    }
}
