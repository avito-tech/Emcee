import Foundation
import QueueModels

public enum BalancingBucketQueueError: Error, CustomStringConvertible {
    case noMatchingQueueFound(requestId: RequestId, workerId: WorkerId)
    case noQueue(jobId: JobId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let requestId, let workerId):
            return "No matching queue found for \(requestId) from \(workerId)"
        case .noQueue(let jobId):
            return "Can't find queue for for \(jobId)"
        }
    }
}
