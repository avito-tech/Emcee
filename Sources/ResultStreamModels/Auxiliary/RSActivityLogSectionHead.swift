import Foundation

public struct RSActivityLogSectionHead: Codable, RSTypedValue, Equatable {
    public static let typeName = "ActivityLogSectionHead"
    
    public let domainType: RSString
    public let startTime: RSDate
    public let title: RSString
    
    public init(
        domainType: RSString,
        startTime: RSDate,
        title: RSString
    ) {
        self.domainType = domainType
        self.startTime = startTime
        self.title = title
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        domainType = try container.decode(RSString.self, forKey: .domainType)
        startTime = try container.decode(RSDate.self, forKey: .startTime)
        title = try container.decode(RSString.self, forKey: .title)
    }
}
