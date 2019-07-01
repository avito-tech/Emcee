import Foundation

extension String: ParsableArgument {
    public init(argumentValue: String) {
        self = argumentValue
    }
}
