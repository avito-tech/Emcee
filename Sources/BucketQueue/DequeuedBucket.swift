import Foundation
import QueueModels

public enum DequeueResult: Hashable {
    case queueIsEmpty
    case checkAgainLater(checkAfter: TimeInterval)
    case dequeuedBucket(DequeuedBucket)
    case workerIsNotRegistered
}

public struct DequeuedBucket: CustomStringConvertible, Hashable {
    public let enqueuedBucket: EnqueuedBucket
    public let workerId: WorkerId

    public init(enqueuedBucket: EnqueuedBucket, workerId: WorkerId) {
        self.enqueuedBucket = enqueuedBucket
        self.workerId = workerId
    }
    
    public var description: String {
        return "<\(type(of: self)) \(workerId) \(enqueuedBucket)>"
    }
}
