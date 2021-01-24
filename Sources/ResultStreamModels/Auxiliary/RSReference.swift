import Foundation

public struct RSReference: Codable, RSTypedValue, Equatable {
    public static let typeName = "Reference"
    
    public let id: RSString
    
    public init(id: RSString) {
        self.id = id
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(RSString.self, forKey: .id)
    }
}
