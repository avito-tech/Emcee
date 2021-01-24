import Foundation

public struct RSBool: Codable, RSTypedValue, ExpressibleByBooleanLiteral, Equatable {
    public static let typeName = "Bool"
    
    public let _value: String
    
    public var boolValue: Bool { Bool(_value) ?? false }
    
    public init(_ value: Bool) {
        _value = String(value)
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _value = try container.decode(String.self, forKey: ._value)
    }
    
    public init(booleanLiteral value: BooleanLiteralType) {
        _value = String(value)
    }
}
