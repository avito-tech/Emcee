import Foundation

public protocol RSStreamedEvent: Codable, RSNamedValue, Equatable {
    
    associatedtype Payload: Codable, RSTypedValue, Equatable
    
    var structuredPayload: Payload { get }
    
    init(structuredPayload: Payload)
}

public class RSAbstractStreamedEvent<T: Codable & RSTypedValue & Equatable>: RSStreamedEvent {
    public typealias Payload = T
    
    public class var typeName: String { "StreamedEvent" }
    public class var name: RSString { fatalError("Not implemented") }
    
    public let structuredPayload: T
    
    required public init(structuredPayload: T) {
        self.structuredPayload = structuredPayload
    }
    
    public static func == (lhs: RSAbstractStreamedEvent, rhs: RSAbstractStreamedEvent) -> Bool {
        lhs.structuredPayload == rhs.structuredPayload
    }
    
    public required init(from decoder: Decoder) throws {
        try Self.validate(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        structuredPayload = try container.decode(T.self, forKey: .structuredPayload)
    }
}
