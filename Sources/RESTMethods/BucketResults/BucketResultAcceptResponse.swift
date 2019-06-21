import Foundation
import Models

public enum BucketResultAcceptResponse: Codable, Equatable {
    case bucketResultAccepted(bucketId: BucketId)
    
    private enum CodingKeys: CodingKey {
        case caseId
        case bucketId
    }
    
    private enum CaseId: String, Codable {
        case bucketResultAccepted
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .bucketResultAccepted:
            self = .bucketResultAccepted(bucketId: try container.decode(BucketId.self, forKey: .bucketId))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bucketResultAccepted(let bucketId):
            try container.encode(CaseId.bucketResultAccepted, forKey: .caseId)
            try container.encode(bucketId, forKey: .bucketId)
        }
    }
}
