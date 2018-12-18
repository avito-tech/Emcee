import BucketQueue
import Foundation

public final class BalancingBucketQueueFactory {
    private let bucketQueueFactory: BucketQueueFactory
    private let nothingToDequeueBehavior: NothingToDequeueBehavior

    public init(
        bucketQueueFactory: BucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehavior)
    {
        self.bucketQueueFactory = bucketQueueFactory
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }
    
    public func create() -> BalancingBucketQueue {
        return BalancingBucketQueueImpl(
            bucketQueueFactory: bucketQueueFactory,
            nothingToDequeueBehavior: nothingToDequeueBehavior
        )
    }
}

