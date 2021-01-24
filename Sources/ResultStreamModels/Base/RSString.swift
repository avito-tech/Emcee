import Foundation

public struct RSString: Codable, RSTypedValue, ExpressibleByStringLiteral, Equatable {
    public static let typeName = "String"
    
    public let _value: String
    
    public var stringValue: String { _value }
    
    public init(_ value: String) {
        _value = value
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _value = try container.decode(String.self, forKey: ._value)
    }
    
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        _value = value
    }
}
