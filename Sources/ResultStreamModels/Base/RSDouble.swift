import Foundation

public struct RSDouble: Codable, RSTypedValue, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, Equatable {
    public static let typeName = "Double"
    
    public let doubleValue: Double
    
    public var _value: String { String(doubleValue) }
    
    public init(_ value: Double) {
        doubleValue = value
    }
    
    public init(_ string: String) throws {
        guard let doubleValue = Double(string) else {
            throw NotParsableDouble(value: string)
        }
        self.doubleValue = doubleValue
    }
    
    struct NotParsableDouble: Error, CustomStringConvertible {
        let value: String
        var description: String { "Cannot parse string '\(value)' to double" }
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: _RsTypeKeys.self)
        let value = try container.decode(String.self, forKey: ._value)
        guard let doubleValue = Double(value) else {
            throw NotParsableDouble(value: value)
        }
        self.doubleValue = doubleValue
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        doubleValue = Double(value)
    }
    
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: Double) {
        doubleValue = value
    }
}
