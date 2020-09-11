import BucketQueueModels

public protocol StuckBucketsReenqueuer {
    func reenqueueStuckBuckets() -> [StuckBucket]
}
