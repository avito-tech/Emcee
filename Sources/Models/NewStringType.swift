import Foundation

open class NewStringType: ExpressibleByStringLiteral, Codable, Hashable, CustomStringConvertible {
    public typealias StringLiteralType = String

    public let stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    public var description: String {
        return "\(type(of: self)): \(stringValue)"
    }

    required public init(stringLiteral value: StringLiteralType) {
        stringValue = value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }

    public static func ==(left: NewStringType, right: NewStringType) -> Bool {
        return left.stringValue == right.stringValue
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        stringValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
