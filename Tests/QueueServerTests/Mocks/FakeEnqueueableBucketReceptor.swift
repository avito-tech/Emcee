import BalancingBucketQueue
import Foundation
import Models
import QueueModels
import Types

class FakeEnqueueableBucketReceptor: EnqueueableBucketReceptor {
    var enqueuedJobs = MapWithCollection<PrioritizedJob, Bucket>()
    
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        enqueuedJobs.append(key: prioritizedJob, elements: buckets)
    }
}
