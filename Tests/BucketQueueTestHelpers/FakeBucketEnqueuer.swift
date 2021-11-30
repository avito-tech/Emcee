import BucketQueue
import Foundation
import QueueModels

open class FakeBucketEnqueuer: BucketEnqueuer {
    public var onEnqueue: ([Bucket]) throws -> ()
    
    public init(
        onEnqueue: @escaping ([Bucket]) throws -> () = { _ in }
    ) {
        self.onEnqueue = onEnqueue
    }
    
    public func enqueue(buckets: [Bucket]) throws {
        try onEnqueue(buckets)
    }
}
