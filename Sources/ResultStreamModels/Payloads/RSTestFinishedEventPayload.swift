import Foundation

public struct RSTestFinishedEventPayload: Codable, RSTypedValue, Equatable {
    public static let typeName = "TestFinishedEventPayload"
    
    public let resultInfo: RSStreamedActionResultInfo
    public let test: RSActionTestMetadata
    
    public init(
        resultInfo: RSStreamedActionResultInfo,
        test: RSActionTestMetadata
    ) {
        self.resultInfo = resultInfo
        self.test = test
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        test = try container.decode(RSActionTestMetadata.self, forKey: .test)
    }
}
