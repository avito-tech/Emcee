import Foundation
import Models

public protocol BucketQueue: BucketResultAccepter, DequeueableBucketSource, QueueStateProvider, StuckBucketsReenqueuer {
    func enqueue(buckets: [Bucket])
}
