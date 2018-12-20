import BalancingBucketQueue
import Foundation
import Models

class FakeEnqueueableBucketReceptor: EnqueueableBucketReceptor {
    var enqueuedJobs = MapWithCollection<JobId, Bucket>()
    
    func enqueue(buckets: [Bucket], jobId: JobId) {
        enqueuedJobs.append(key: jobId, elements: buckets)
    }
}
