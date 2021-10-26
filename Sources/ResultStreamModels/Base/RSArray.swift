import Foundation

public struct RSArray<T: Codable & RSTypedValue & Equatable>: Codable, RSTypedValue, Equatable, ExpressibleByArrayLiteral {
    public static var typeName: String { "Array" }
    
    private let _values: [T]
    
    public var values: [T] { _values }
    
    public init(_ values: [T]) {
        _values = values
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _values = try container.decode([T].self, forKey: ._values)
    }
    
    public typealias ArrayLiteralElement = T
    public init(arrayLiteral elements: T...) {
        _values = elements
    }
}
