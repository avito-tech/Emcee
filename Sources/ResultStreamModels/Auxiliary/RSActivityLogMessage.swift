import Foundation

public struct RSActivityLogMessage: RSTypedValue, Codable, Equatable {
    public static let typeName = "ActivityLogMessage"
    
    public let shortTitle: RSString
    public let title: RSString
    public let type: RSString
    
    public init(
        shortTitle: RSString,
        title: RSString,
        type: RSString
    ) {
        self.shortTitle = shortTitle
        self.title = title
        self.type = type
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        shortTitle = try container.decode(RSString.self, forKey: .shortTitle)
        title = try container.decode(RSString.self, forKey: .title)
        type = try container.decode(RSString.self, forKey: .type)
    }
}
