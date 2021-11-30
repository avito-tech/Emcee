public protocol StatefulBucketQueueProvider {
    func createStatefulBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> StatefulBucketQueue
}
