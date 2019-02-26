import Foundation
import Models

public enum DequeueResult: Hashable {
    case queueIsEmpty
    case checkAgainLater(checkAfter: TimeInterval)
    case dequeuedBucket(DequeuedBucket)
    case workerBlocked
}

public struct DequeuedBucket: CustomStringConvertible, Hashable {
    public let enqueuedBucket: EnqueuedBucket
    public let workerId: String
    public let requestId: String

    public init(enqueuedBucket: EnqueuedBucket, workerId: String, requestId: String) {
        self.enqueuedBucket = enqueuedBucket
        self.workerId = workerId
        self.requestId = requestId
    }
    
    public var description: String {
        return "<\(type(of: self)) workerId: \(workerId), requestId: \(requestId), enqueuedBucket: \(enqueuedBucket)>"
    }
}
