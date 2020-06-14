import Foundation
import Models

public enum DequeueResult: Hashable {
    case queueIsEmpty
    case checkAgainLater(checkAfter: TimeInterval)
    case dequeuedBucket(DequeuedBucket)
    case workerIsNotRegistered
}

public struct DequeuedBucket: CustomStringConvertible, Hashable {
    public let enqueuedBucket: EnqueuedBucket
    public let workerId: WorkerId
    public let requestId: RequestId

    public init(enqueuedBucket: EnqueuedBucket, workerId: WorkerId, requestId: RequestId) {
        self.enqueuedBucket = enqueuedBucket
        self.workerId = workerId
        self.requestId = requestId
    }
    
    public var description: String {
        return "<\(type(of: self)) \(workerId) \(requestId) \(enqueuedBucket)>"
    }
}
