import Foundation

open class NewStringType: ExpressibleByStringLiteral, Codable, Hashable, CustomStringConvertible, Comparable {
    public typealias StringLiteralType = String

    public let value: String

    public init(value: String) {
        self.value = value
    }

    public var description: String {
        return "\(type(of: self)): \(value)"
    }

    required public init(stringLiteral value: StringLiteralType) {
        self.value = value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func ==(left: NewStringType, right: NewStringType) -> Bool {
        return left.value == right.value
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public static func < (left: NewStringType, right: NewStringType) -> Bool {
        return left.value < right.value
    }
}
