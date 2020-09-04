import BucketQueue
import Foundation

public class FakeBucketQueueFactory: BucketQueueFactory {
    public var tuner: (FakeBucketQueue) -> () = { _ in }
    
    public init() {}
    
    public func createBucketQueue() -> BucketQueue {
        let bucketQueue = FakeBucketQueue()
        tuner(bucketQueue)
        return bucketQueue
    }
}
