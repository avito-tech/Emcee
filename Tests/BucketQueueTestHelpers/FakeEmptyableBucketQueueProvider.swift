import BucketQueue
import Foundation

open class FakeEmptyableBucketQueueProvider: EmptyableBucketQueueProvider {
    public var fakeEmptyableBucketQueue = FakeEmptyableBucketQueue(onRemoveAllEnqueuedBuckets: {})
    
    public func createEmptyableBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> EmptyableBucketQueue {
        fakeEmptyableBucketQueue
    }
    
    public init() {}
}
