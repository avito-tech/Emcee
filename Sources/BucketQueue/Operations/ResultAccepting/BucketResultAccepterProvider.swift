public protocol BucketResultAcceptorProvider {
    func createBucketResultAcceptor(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketResultAcceptor
}
