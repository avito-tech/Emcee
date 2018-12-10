import BucketQueue
import Foundation

public final class BalancingBucketQueueFactory {
    private let bucketQueueFactory: BucketQueueFactory
    private let checkAgainTimeInterval: TimeInterval

    public init(
        bucketQueueFactory: BucketQueueFactory,
        checkAgainTimeInterval: TimeInterval)
    {
        self.bucketQueueFactory = bucketQueueFactory
        self.checkAgainTimeInterval = checkAgainTimeInterval
    }
    
    public func create() -> BalancingBucketQueue {
        return BalancingBucketQueueImpl(
            bucketQueueFactory: bucketQueueFactory,
            checkAgainTimeInterval: checkAgainTimeInterval
        )
    }
}

