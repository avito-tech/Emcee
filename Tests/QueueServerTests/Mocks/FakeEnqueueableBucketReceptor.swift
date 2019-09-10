import BalancingBucketQueue
import Foundation
import Models

class FakeEnqueueableBucketReceptor: EnqueueableBucketReceptor {
    var enqueuedJobs = MapWithCollection<PrioritizedJob, Bucket>()
    
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        enqueuedJobs.append(key: prioritizedJob, elements: buckets)
    }
}
