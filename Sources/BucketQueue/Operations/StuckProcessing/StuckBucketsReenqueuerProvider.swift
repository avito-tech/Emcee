public protocol StuckBucketsReenqueuerProvider {
    func createStuckBucketsReenqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> StuckBucketsReenqueuer
}
