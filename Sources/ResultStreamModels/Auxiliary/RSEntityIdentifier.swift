import Foundation

public struct RSEntityIdentifier: Codable, RSTypedValue, Equatable {
    public static let typeName = "EntityIdentifier"
    
    public let containerName: RSString
    public let entityName: RSString
    public let entityType: RSString
    public let sharedState: RSString
    
    public init(
        containerName: RSString,
        entityName: RSString,
        entityType: RSString,
        sharedState: RSString
    ) {
        self.containerName = containerName
        self.entityName = entityName
        self.entityType = entityType
        self.sharedState = sharedState
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        containerName = try container.decode(RSString.self, forKey: .containerName)
        entityName = try container.decode(RSString.self, forKey: .entityName)
        entityType = try container.decode(RSString.self, forKey: .entityType)
        sharedState = try container.decode(RSString.self, forKey: .sharedState)
    }
}
