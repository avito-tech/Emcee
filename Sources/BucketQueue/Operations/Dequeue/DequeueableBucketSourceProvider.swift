import Foundation

public protocol DequeueableBucketSourceProvider {
    
    /// Returns `DequeueableBucketSource` which will perfrom dequeue from the provided `BucketQueueHolder`.
    func createDequeueableBucketSource(
        bucketQueueHolder: BucketQueueHolder
    ) -> DequeueableBucketSource
}
