import Foundation

public struct RSTestEventPayload<Identifier: RSActionTestSummaryIdentifiableObject>: Codable, RSTypedValue, Equatable {
    public static var typeName: String { "TestEventPayload" }
    
    public let resultInfo: RSStreamedActionResultInfo
    public let testIdentifier: Identifier
    
    public init(
        resultInfo: RSStreamedActionResultInfo,
        testIdentifier: Identifier
    ) {
        self.resultInfo = resultInfo
        self.testIdentifier = testIdentifier
    }
    
    public init(from decoder: Decoder) throws {
        try Self.validateRsType(decoder: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultInfo = try container.decode(RSStreamedActionResultInfo.self, forKey: .resultInfo)
        testIdentifier = try container.decode(Identifier.self, forKey: .testIdentifier)
    }
}
