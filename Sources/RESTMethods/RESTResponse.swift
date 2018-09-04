import Foundation
import Models

public enum RESTResponse: Codable {
    case bucketDequeued(bucket: Bucket)
    case bucketResultAccepted(bucketId: String)
    case queueIsEmpty
    case checkAgainLater(checkAfter: TimeInterval)
    case workerRegisterSuccess(workerConfiguration: WorkerConfiguration)
    case workerBlocked
    
    enum CodingKeys: CodingKey {
        case responseType
        case bucketDequeued
        case bucketResultAccepted
        case queueIsEmpty
        case checkAgainLater
        case workerRegisterSuccess
        case workerBlocked
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .bucketDequeued(let bucket):
            try container.encode(ResponseType.bucketDequeued, forKey: .responseType)
            try container.encode(bucket, forKey: .bucketDequeued)
        case .bucketResultAccepted(let bucketId):
            try container.encode(ResponseType.bucketResultAccepted, forKey: .responseType)
            try container.encode(bucketId, forKey: .bucketResultAccepted)
        case .queueIsEmpty:
            try container.encode(ResponseType.queueIsEmpty, forKey: .responseType)
            try container.encode(true, forKey: .queueIsEmpty)
        case .checkAgainLater(let checkAfter):
            try container.encode(ResponseType.checkAgainLater, forKey: .responseType)
            try container.encode(checkAfter, forKey: .checkAgainLater)
        case .workerRegisterSuccess(let workerConfiguration):
            try container.encode(ResponseType.workerRegisterSuccess, forKey: .responseType)
            try container.encode(workerConfiguration, forKey: .workerRegisterSuccess)
        case .workerBlocked:
            try container.encode(ResponseType.workerBlocked, forKey: .responseType)
            try container.encode(true, forKey: .workerBlocked)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseType = try container.decode(ResponseType.self, forKey: .responseType)
        switch responseType {
        case .bucketDequeued:
            let dequeuedBucket = try container.decode(Bucket.self, forKey: .bucketDequeued)
            self = .bucketDequeued(bucket: dequeuedBucket)
        case .bucketResultAccepted:
            let bucketId = try container.decode(String.self, forKey: .bucketResultAccepted)
            self = .bucketResultAccepted(bucketId: bucketId)
        case .queueIsEmpty:
            self = .queueIsEmpty
        case .checkAgainLater:
            let checkAfter = try container.decode(TimeInterval.self, forKey: .checkAgainLater)
            self = .checkAgainLater(checkAfter: checkAfter)
        case .workerRegisterSuccess:
            let workerConfiguration = try container.decode(WorkerConfiguration.self, forKey: .workerRegisterSuccess)
            self = .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .workerBlocked:
            self = .workerBlocked
        }
    }
    
    private enum ResponseType: String, Codable {
        case bucketDequeued
        case bucketResultAccepted
        case queueIsEmpty
        case checkAgainLater
        case workerRegisterSuccess
        case workerBlocked
    }
}
