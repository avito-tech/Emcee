import Foundation

public final class Version: ExpressibleByStringLiteral, Codable, Hashable, CustomStringConvertible {
    public typealias StringLiteralType = String
    
    public let stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public var description: String {
        return stringValue
    }
    
    required public init(stringLiteral value: StringLiteralType) {
        stringValue = value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }
    
    public static func ==(left: Version, right: Version) -> Bool {
        return left.stringValue == right.stringValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        stringValue = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
