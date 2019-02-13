import Foundation

public final class Priority: Comparable, Hashable, Codable, CustomStringConvertible {
    public let intValue: UInt

    public init(intValue: UInt) throws {
        try Priority.validate(intValue: intValue)
        self.intValue = intValue
    }
    
    private static let maximumIntValue: UInt = 999
    public static let highest = try! Priority(intValue: maximumIntValue)
    public static let medium = try! Priority(intValue: 500)
    public static let lowest = try! Priority(intValue: 0)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(intValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intValue = try container.decode(UInt.self)
        try Priority.validate(intValue: intValue)
        self.intValue = intValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(intValue)
    }
    
    public var description: String {
        return "\(intValue) priority"
    }
    
    public static func < (left: Priority, right: Priority) -> Bool {
        return left.intValue < right.intValue
    }
    
    public static func == (left: Priority, right: Priority) -> Bool {
        return left.intValue == right.intValue
    }
    
    private static func validate(intValue: UInt) throws {
        struct InvalidPriorityValue: Error, CustomStringConvertible {
            let value: UInt
            var description: String {
                return "Invalid priority: \(value). Expected value to be in range [0...\(Priority.maximumIntValue)]"
            }
        }
        if intValue > maximumIntValue {
            throw InvalidPriorityValue(value: intValue)
        }
    }
}
