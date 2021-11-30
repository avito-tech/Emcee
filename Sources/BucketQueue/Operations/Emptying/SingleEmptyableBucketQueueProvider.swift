public final class SingleEmptyableBucketQueueProvider: EmptyableBucketQueueProvider {
    public init() {}
    
    public func createEmptyableBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> EmptyableBucketQueue {
        SingleEmptyableBucketQueue(bucketQueueHolder: bucketQueueHolder)
    }
}
