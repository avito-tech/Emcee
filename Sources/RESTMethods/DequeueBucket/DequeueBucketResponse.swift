import Foundation
import QueueModels

public enum DequeueBucketResponse: Codable, Equatable {
    case bucketDequeued(bucket: Bucket)
    case checkAgainLater(checkAfter: TimeInterval)
    
    private enum CodingKeys: CodingKey {
        case caseId
        case bucket
        case checkAfter
    }
    
    private enum CaseId: String, Codable {
        case bucketDequeued
        case checkAgainLater
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .bucketDequeued:
            self = .bucketDequeued(bucket: try container.decode(Bucket.self, forKey: .bucket))
        case .checkAgainLater:
            self = .checkAgainLater(checkAfter: try container.decode(TimeInterval.self, forKey: .checkAfter))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bucketDequeued(let bucket):
            try container.encode(CaseId.bucketDequeued, forKey: .caseId)
            try container.encode(bucket, forKey: .bucket)
        case .checkAgainLater(let checkAfter):
            try container.encode(CaseId.checkAgainLater, forKey: .caseId)
            try container.encode(checkAfter, forKey: .checkAfter)
        }
    }
}
