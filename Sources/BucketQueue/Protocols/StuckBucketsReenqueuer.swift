import BucketQueueModels

public protocol StuckBucketsReenqueuer {
    func reenqueueStuckBuckets() throws -> [StuckBucket]
}
