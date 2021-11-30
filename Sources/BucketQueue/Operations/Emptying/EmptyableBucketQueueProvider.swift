public protocol EmptyableBucketQueueProvider {
    func createEmptyableBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> EmptyableBucketQueue
}
