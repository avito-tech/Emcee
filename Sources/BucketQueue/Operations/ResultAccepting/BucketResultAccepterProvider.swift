public protocol BucketResultAccepterProvider {
    func createBucketResultAccepter(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketResultAccepter
}
