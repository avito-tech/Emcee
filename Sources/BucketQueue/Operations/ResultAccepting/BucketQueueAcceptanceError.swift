import Foundation
import QueueModels

public enum BucketQueueAcceptanceError: Error, CustomStringConvertible {
    case noDequeuedBucket(bucketId: BucketId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case let .noDequeuedBucket(bucketId, workerId):
            return "Bucket with \(bucketId) and dequeued by \(workerId) cannot be found"
        }
    }
}
