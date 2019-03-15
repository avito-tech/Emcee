import Foundation
import Models

public enum DequeueBucketResponse: Codable, Equatable {
    case bucketDequeued(bucket: Bucket)
    case queueIsEmpty
    case workerIsNotAlive
    case workerIsBlocked
    case checkAgainLater(checkAfter: TimeInterval)
    
    private enum CodingKeys: CodingKey {
        case caseId
        case bucket
        case checkAfter
    }
    
    private enum CaseId: String, Codable {
        case bucketDequeued
        case queueIsEmpty
        case workerIsNotAlive
        case workerIsBlocked
        case checkAgainLater
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .bucketDequeued:
            self = .bucketDequeued(bucket: try container.decode(Bucket.self, forKey: .bucket))
        case .queueIsEmpty:
            self = .queueIsEmpty
        case .workerIsNotAlive:
            self = .workerIsNotAlive
        case .checkAgainLater:
            self = .checkAgainLater(checkAfter: try container.decode(TimeInterval.self, forKey: .checkAfter))
        case .workerIsBlocked:
            self = .workerIsBlocked
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
        case .queueIsEmpty:
            try container.encode(CaseId.queueIsEmpty, forKey: .caseId)
        case .workerIsNotAlive:
            try container.encode(CaseId.workerIsNotAlive, forKey: .caseId)
        case .workerIsBlocked:
            try container.encode(CaseId.workerIsBlocked, forKey: .caseId)
        }
    }
}
