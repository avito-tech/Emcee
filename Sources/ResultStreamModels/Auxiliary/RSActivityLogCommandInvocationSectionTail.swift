import Foundation

public struct RSActivityLogCommandInvocationSectionTail: Codable, RSTypedValue, Equatable {
    public static let typeName = "ActivityLogCommandInvocationSectionTail"
    
    public let duration: RSDouble?
    public let result: RSString
    
    public init(
        duration: RSDouble?,
        result: RSString
    ) {
        self.duration = duration
        self.result = result
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        duration = try container.decodeIfPresent(RSDouble.self, forKey: .duration)
        result = try container.decode(RSString.self, forKey: .result)
    }
}
