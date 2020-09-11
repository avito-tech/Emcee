import QueueModels

public protocol BucketEnqueuer {
    func enqueue(buckets: [Bucket]) throws
}
