import Foundation
import Models
import QueueModels

public enum ResultAcceptanceError: Error, CustomStringConvertible {
    case noDequeuedBucket(requestId: RequestId, workerId: WorkerId)
    
    public var description: String {
        switch self {
        case let .noDequeuedBucket(requestId, workerId):
            return "Cannot accept bucket results with \(requestId) \(workerId). This request does not have corresponding dequeued bucket."
        }
    }
}
