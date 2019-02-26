import Foundation
import Models

public final class EnqueuedBucket: Hashable, Comparable, CustomStringConvertible {
    public let bucket: Bucket
    public let enqueueTimestamp: Date

    public init(bucket: Bucket, enqueueTimestamp: Date) {
        self.bucket = bucket
        self.enqueueTimestamp = enqueueTimestamp
    }
    
    public var description: String {
        return "<\(type(of: self)) enqueued at: \(enqueueTimestamp) bucket: \(bucket)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bucket)
        hasher.combine(enqueueTimestamp)
    }
    
    public static func == (left: EnqueuedBucket, right: EnqueuedBucket) -> Bool {
        return left.bucket == right.bucket
            && left.enqueueTimestamp == right.enqueueTimestamp
    }
    
    public static func < (left: EnqueuedBucket, right: EnqueuedBucket) -> Bool {
        return left.enqueueTimestamp < right.enqueueTimestamp
    }
}
