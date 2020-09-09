import Foundation
import QueueModels

public enum ResultAcceptanceError: Error, CustomStringConvertible {
    case noDequeuedBucket(bucketId: BucketId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case let .noDequeuedBucket(bucketId, workerId):
            return "Cannot accept bucket results with \(bucketId) from \(workerId). This worker was not associated with that bucket id."
        }
    }
}
