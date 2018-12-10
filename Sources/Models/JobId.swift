import Foundation

public final class JobId: Codable, Hashable, ExpressibleByStringLiteral {
    
    public typealias StringLiteralType = String
    
    public let value: String
    
    public init(stringLiteral value: StringLiteralType) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public static func == (left: JobId, right: JobId) -> Bool {
        return left.value == right.value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
