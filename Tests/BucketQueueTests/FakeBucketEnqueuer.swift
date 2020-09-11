import BucketQueue
import Foundation
import QueueModels


class FakeBucketEnqueuer: BucketEnqueuer {
    var enqueuedBuckets = [Bucket]()
    
    func enqueue(buckets: [Bucket]) throws {
        enqueuedBuckets.append(contentsOf: buckets)
    }
}
