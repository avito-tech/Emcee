import Foundation

public struct RSInt: Codable, RSTypedValue, ExpressibleByIntegerLiteral, Equatable {
    public static let typeName = "Int"
    
    public let intValue: Int
    
    public var _value: String { String(intValue) }
    
    public init(_ value: Int) {
        intValue = value
    }
    
    public init(_ string: String) throws {
        guard let intValue = Int(string) else {
            throw NotParsableInt(value: string)
        }
        self.intValue = intValue
    }
    
    struct NotParsableInt: Error, CustomStringConvertible {
        let value: String
        var description: String { "Cannot parse string '\(value)' to int" }
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: _RsTypeKeys.self)
        let value = try container.decode(String.self, forKey: ._value)
        guard let intValue = Int(value) else {
            throw NotParsableInt(value: value)
        }
        self.intValue = intValue
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        intValue = value
    }
}
