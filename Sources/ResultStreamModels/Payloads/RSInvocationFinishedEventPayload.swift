import Foundation

public struct RSInvocationFinishedEventPayload: Codable, RSTypedValue, Equatable {
    public static var typeName: String { "InvocationFinishedEventPayload" }
    
    public let recordRef: RSReference?
    
    public init(recordRef: RSReference?) {
        self.recordRef = recordRef
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordRef = try container.decodeIfPresent(RSReference.self, forKey: .recordRef)
    }
}
