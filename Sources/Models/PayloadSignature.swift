import Foundation

public final class PayloadSignature: Codable, Hashable, CustomStringConvertible {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public var description: String {
        return value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func == (left: PayloadSignature, right: PayloadSignature) -> Bool {
        return left.value == right.value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
