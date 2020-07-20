import Foundation

open class NewIntType: ExpressibleByIntegerLiteral, Codable, Hashable, CustomStringConvertible, Comparable {
    public typealias IntegerLiteralType = Int

    public let value: Int

    public init(value: Int) {
        self.value = value
    }
    
    public required init(integerLiteral value: Int) {
        self.value = value
    }

    public var description: String {
        return "\(value)"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func ==(left: NewIntType, right: NewIntType) -> Bool {
        return left.value == right.value
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public static func < (left: NewIntType, right: NewIntType) -> Bool {
        return left.value < right.value
    }
}
