public final class SingleStatefulBucketQueueProvider: StatefulBucketQueueProvider {
    public init() {}
    
    public func createStatefulBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> StatefulBucketQueue {
        return SingleStatefulBucketQueue(bucketQueueHolder: bucketQueueHolder)
    }
}
