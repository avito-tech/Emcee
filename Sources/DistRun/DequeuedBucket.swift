import Foundation
import Models

public enum DequeueResult {
    case queueIsEmpty
    case queueIsEmptyButNotResultsAreAvailable
    case dequeuedBucket(DequeuedBucket)
    case workerBlocked
}

public struct DequeuedBucket: CustomStringConvertible, Hashable {
    public let bucket: Bucket
    public let workerId: String
    public let requestId: String

    public init(bucket: Bucket, workerId: String, requestId: String) {
        self.bucket = bucket
        self.workerId = workerId
        self.requestId = requestId
    }
    
    public var description: String {
        return "<\(type(of: self)) workerId: \(workerId), requestId: \(requestId), bucket: \(bucket)>"
    }
}
