import Foundation
import QueueModels

public protocol BucketQueue: BucketResultAccepter, DequeueableBucketSource, EmptyableBucketQueue, RunningQueueStateProvider, StuckBucketsReenqueuer {
    func enqueue(buckets: [Bucket]) throws
}
