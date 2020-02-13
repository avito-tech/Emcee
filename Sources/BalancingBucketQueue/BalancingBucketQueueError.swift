import Foundation
import Models
import QueueModels

public enum BalancingBucketQueueError: Error, CustomStringConvertible {
    case noMatchingQueueFound(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId)
    case noQueue(jobId: JobId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let testingResult, let requestId, let workerId):
            return "Can't accept result for \(testingResult.bucketId): no matching queue found for \(requestId) from \(workerId)"
        case .noQueue(let jobId):
            return "Can't find queue for for \(jobId)"
        }
    }
}
