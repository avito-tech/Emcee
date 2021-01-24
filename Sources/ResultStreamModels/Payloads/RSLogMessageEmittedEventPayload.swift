import Foundation

public struct RSLogMessageEmittedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "LogMessageEmittedEventPayload"

    public let message: RSActivityLogMessage
    public let sectionIndex: RSInt
    public let resultInfo: RSStreamedActionResultInfo
    
    public init(
        message: RSActivityLogMessage,
        sectionIndex: RSInt,
        resultInfo: RSStreamedActionResultInfo
    ) {
        self.message = message
        self.sectionIndex = sectionIndex
        self.resultInfo = resultInfo
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        message = try container.decode(RSActivityLogMessage.self, forKey: .message)
        sectionIndex = try container.decode(RSInt.self, forKey: .sectionIndex)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
    }
}
