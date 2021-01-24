import Foundation

public struct RSActionsInvocationMetadata: Codable, RSTypedValue, Equatable {
    public static let typeName = "ActionsInvocationMetadata"
    
    public let creatingWorkspaceFilePath: RSString
    public let schemeIdentifier: RSEntityIdentifier
    public let uniqueIdentifier: RSString
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)

        creatingWorkspaceFilePath = try container.decode(RSString.self, forKey: .creatingWorkspaceFilePath)
        schemeIdentifier = try container.decode(RSEntityIdentifier.self, forKey: .schemeIdentifier)
        uniqueIdentifier = try container.decode(RSString.self, forKey: .uniqueIdentifier)
    }
    
    public init(
        creatingWorkspaceFilePath: RSString,
        schemeIdentifier: RSEntityIdentifier,
        uniqueIdentifier: RSString
    ) {
        self.creatingWorkspaceFilePath = creatingWorkspaceFilePath
        self.schemeIdentifier = schemeIdentifier
        self.uniqueIdentifier = uniqueIdentifier
    }
}
