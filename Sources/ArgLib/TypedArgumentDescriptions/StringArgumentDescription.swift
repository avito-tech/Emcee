import Foundation

public class StringArgumentDescription: ArgumentDescription {
    public typealias ValueType = String
}

extension String: ParsableArgument {
    public init(argumentValue: String) {
        self = argumentValue
    }
}
