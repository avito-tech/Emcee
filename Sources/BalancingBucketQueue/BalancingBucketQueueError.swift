import Foundation
import Models

public enum BalancingBucketQueueError: Error, CustomStringConvertible {
    case noMatchingQueueFound(testingResult: TestingResult, requestId: String, workerId: String)
    case noQueue(jobId: JobId)
    
    public var description: String {
        switch self {
        case .noMatchingQueueFound(let testingResult, let requestId, let workerId):
            return "Error: can't accept result for bucket '\(testingResult.bucketId)': no matching queue found for request '\(requestId)' from '\(workerId)'"
        case .noQueue(let jobId):
            return "Error: queue for job '\(jobId)' not found"
        }
    }
}
