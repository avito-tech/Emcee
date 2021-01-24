import Foundation

public struct RSLogSectionAttachedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "LogSectionAttachedEventPayload"
    public let childSectionIndex: RSInt
    public let resultInfo: RSStreamedActionResultInfo
    
    public init(
        childSectionIndex: RSInt,
        resultInfo: RSStreamedActionResultInfo
    ) {
        self.childSectionIndex = childSectionIndex
        self.resultInfo = resultInfo
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        childSectionIndex = try container.decode(RSInt.self, forKey: .childSectionIndex)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
    }
}
