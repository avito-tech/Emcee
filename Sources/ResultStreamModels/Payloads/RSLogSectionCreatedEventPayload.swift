import Foundation

public struct RSLogSectionCreatedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "LogSectionCreatedEventPayload"
    public let head: RSActivityLogSectionHead
    public let resultInfo: RSStreamedActionResultInfo
    public let sectionIndex: RSInt
    
    public init(
        head: RSActivityLogSectionHead,
        resultInfo: RSStreamedActionResultInfo,
        sectionIndex: RSInt
    ) {
        self.head = head
        self.resultInfo = resultInfo
        self.sectionIndex = sectionIndex
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        head = try container.decode(RSActivityLogSectionHead.self, forKey: .head)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        sectionIndex = try container.decode(RSInt.self, forKey: .sectionIndex)
    }
}
