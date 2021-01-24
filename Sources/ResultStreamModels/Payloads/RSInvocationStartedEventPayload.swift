import Foundation

public struct RSInvocationStartedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "InvocationStartedEventPayload"
    public let metadata: RSActionsInvocationMetadata
    
    public init(metadata: RSActionsInvocationMetadata) {
        self.metadata = metadata
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        metadata = try container.decode(RSActionsInvocationMetadata.self, forKey: .metadata)
    }
}
