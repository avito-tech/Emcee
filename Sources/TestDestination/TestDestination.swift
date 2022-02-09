import Foundation


/// This is an abstract holder for keyed values which describe test destination.
/// E.g. for Apple it contains simRuntime, simDeviceType fields, and for Android it contains sdkVersion and deviceType.
/// It is better to extract values from this object and then use them instead of passing `TestDestination` object down the call stack.
public final class TestDestination: Hashable, Codable, CustomStringConvertible {
    private let fields: [String: Value]
    
    public init() {
        self.fields = [:]
    }
    
    private init(fields: [String: Value]) {
        self.fields = fields
    }
    
    public func add(key: String, value: String) -> Self {
        var fields = self.fields
        fields[key] = .string(value)
        return Self(fields: fields)
    }
    
    public func add(key: String, value: Int) -> Self {
        var fields = self.fields
        fields[key] = .int(value)
        return Self(fields: fields)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fields)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.fields = try container.decode([String: Value].self)
    }
    
    public var description: String {
        fields.sorted { left, right in
            left.key < right.key
        }.map { (key: String, value: Value) in
            "\(key): \(value)"
        }.joined(separator: " ")
    }
    
    public enum Errors: Error {
        case noValue(key: String)
        case typeMismatch(key: String, expectedType: Any, actualType: Any)
    }
    
    public func value<T>(_ key: String) throws -> T {
        guard let value = fields[key] else { throw Errors.noValue(key: key) }
        guard let typedValue = value.to(T.self) else {
            throw Errors.typeMismatch(key: key, expectedType: T.self, actualType: type(of: value.value))
        }
        return typedValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fields)
    }
    
    public static func == (lhs: TestDestination, rhs: TestDestination) -> Bool {
        lhs.fields == rhs.fields
    }
}
