import Foundation

enum Value: Hashable, Codable, CustomStringConvertible {
    case string(String)
    case int(Int)
    
    var value: Any {
        switch self {
        case let .string(value): return value
        case let .int(value): return value
        }
    }
    
    func to<T>(_ type: T.Type) -> T? {
        value as? T
    }
    
    var description: String {
        switch self {
        case let .string(value): return value
        case let .int(value): return "\(value)"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .string(try container.decode(String.self))
        } catch {
            self = .int(try container.decode(Int.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        }
    }
}
