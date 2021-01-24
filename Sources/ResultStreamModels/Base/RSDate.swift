import Foundation

public struct RSDate: Codable, RSTypedValue, Equatable {
    public static let typeName = "Date"
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"
        return formatter
    }()
    
    public let dateValue: Date
    public var _value: String { Self.dateFormatter.string(from: dateValue) }
    
    public init(_ date: Date) {
        dateValue = date
    }
    
    struct NotParsableDateValue: Error, CustomStringConvertible {
        let value: String
        var description: String { "Cannot parse date: \(value)" }
    }
    
    public init(_ string: String) throws {
        guard let date = Self.dateFormatter.date(from: string) else {
            throw NotParsableDateValue(value: string)
        }
        dateValue = date
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: _RsTypeKeys.self)
        let value = try container.decode(String.self, forKey: ._value)
        guard let dateValue = Self.dateFormatter.date(from: value) else {
            throw NotParsableDateValue(value: value)
        }
        self.dateValue = dateValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _RsTypeKeys.self)
        try container.encode(dateValue, forKey: ._value)
    }
}
