import Foundation
import Models

public protocol EnqueueableBucketReceptor {
    /// Enqueues buckets to a given job. If job does not exist, will create a new job with given id.
    func enqueue(buckets: [Bucket], jobId: JobId)
}
