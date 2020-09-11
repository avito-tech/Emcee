import Foundation

public final class SingleEmptyableBucketQueue: EmptyableBucketQueue {
    private let bucketQueueHolder: BucketQueueHolder
    
    public init(bucketQueueHolder: BucketQueueHolder) {
        self.bucketQueueHolder = bucketQueueHolder
    }
    
    public func removeAllEnqueuedBuckets() {
        bucketQueueHolder.performWithExclusiveAccess {
            bucketQueueHolder.removeAllEnqueuedBuckets()
        }
    }
}
