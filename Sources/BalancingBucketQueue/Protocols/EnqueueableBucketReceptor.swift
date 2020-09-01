import Foundation
import QueueModels

public protocol EnqueueableBucketReceptor {
    /// Enqueues buckets to a given job. If job does not exist, will create a new job with given id and priority.
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) throws
}
