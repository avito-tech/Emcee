import Foundation
import Models

public protocol BucketQueue: BucketResultAccepter, DequeueableBucketSource, EmptyableBucketQueue, RunningQueueStateProvider, StuckBucketsReenqueuer {
    func enqueue(buckets: [Bucket])
}
