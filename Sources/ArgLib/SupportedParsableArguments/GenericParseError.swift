public struct GenericParseError<T>: Error, CustomStringConvertible {
    public let argumentValue: String
    
    public init(argumentValue: String) {
        self.argumentValue = argumentValue
    }
    
    public var description: String {
        return "Unable to convert '\(argumentValue)' into \(T.self) type"
    }
}
