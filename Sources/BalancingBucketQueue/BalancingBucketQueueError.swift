import Foundation
import QueueModels

public enum BalancingBucketQueueError: Error, CustomStringConvertible {
    case noMatchingQueueFound(bucketId: BucketId, workerId: WorkerId)
    case noQueue(jobId: JobId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let bucketId, let workerId):
            return "Can't accept result for \(bucketId): no matching queue found for testing result from \(workerId)"
        case .noQueue(let jobId):
            return "Can't find queue for for \(jobId)"
        }
    }
}
