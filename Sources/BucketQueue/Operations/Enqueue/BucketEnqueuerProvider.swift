public protocol BucketEnqueuerProvider {
    func createBucketEnqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketEnqueuer
}
