import Foundation

public struct DateSince1970ReferenceDate: Codable, Hashable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let date: Date
    
    public init(timeIntervalSince1970: TimeInterval) {
        date = Date(timeIntervalSince1970: timeIntervalSince1970)
    }
    
    public typealias FloatLiteralType = Double
    public init(floatLiteral: TimeInterval) {
        date = Date(timeIntervalSince1970: floatLiteral)
    }
    
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) {
        date = Date(timeIntervalSince1970: TimeInterval(value))
    }
    
    public var timeIntervalSince1970: TimeInterval {
        date.timeIntervalSince1970
    }
    
    public func addingTimeInterval(_ value: TimeInterval) -> Self {
        return Self(timeIntervalSince1970: timeIntervalSince1970 + value)
    }
    
    public static func - (lhs: Self, rhs: IntegerLiteralType) -> Self {
        return lhs.addingTimeInterval(-TimeInterval(rhs))
    }
    
    public static func + (lhs: Self, rhs: IntegerLiteralType) -> Self {
        return lhs.addingTimeInterval(TimeInterval(rhs))
    }
    
    public static func - (lhs: Self, rhs: FloatLiteralType) -> Self {
        return lhs.addingTimeInterval(-rhs)
    }
    
    public static func + (lhs: Self, rhs: FloatLiteralType) -> Self {
        return lhs.addingTimeInterval(rhs)
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}
