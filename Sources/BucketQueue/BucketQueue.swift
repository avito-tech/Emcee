import Foundation
import Models
import QueueModels

public protocol BucketQueue: BucketResultAccepter, DequeueableBucketSource, EmptyableBucketQueue, RunningQueueStateProvider, StuckBucketsReenqueuer {
    func enqueue(buckets: [Bucket])
}
