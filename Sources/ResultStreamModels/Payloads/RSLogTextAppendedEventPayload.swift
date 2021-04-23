import Foundation

public struct RSLogTextAppendedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "LogTextAppendedEventPayload"
    public let text: RSString
    public let resultInfo: RSStreamedActionResultInfo?
    public let sectionIndex: RSInt
    
    public init(
        text: RSString,
        resultInfo: RSStreamedActionResultInfo?,
        sectionIndex: RSInt
    ) {
        self.text = text
        self.resultInfo = resultInfo
        self.sectionIndex = sectionIndex
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(RSString.self, forKey: .text)
        resultInfo = try container.decodeIfPresent(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        sectionIndex = try container.decode(RSInt.self, forKey: .sectionIndex)
    }
}
