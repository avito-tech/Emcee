import Foundation

public struct RSLogSectionClosedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "LogSectionClosedEventPayload"
    public let sectionIndex: RSInt
    public let resultInfo: RSStreamedActionResultInfo
    public let tail: RSActivityLogCommandInvocationSectionTail
    
    public init(
        sectionIndex: RSInt,
        resultInfo: RSStreamedActionResultInfo,
        tail: RSActivityLogCommandInvocationSectionTail
    ) {
        self.sectionIndex = sectionIndex
        self.resultInfo = resultInfo
        self.tail = tail
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sectionIndex = try container.decode(RSInt.self, forKey: .sectionIndex)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        tail = try container.decode(RSActivityLogCommandInvocationSectionTail.self, forKey: .tail)
    }
}
