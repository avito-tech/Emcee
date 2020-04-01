import BucketQueue
import Foundation
import QueueCommunication

public final class BalancingBucketQueueFactory {
    private let bucketQueueFactory: BucketQueueFactory
    private let nothingToDequeueBehavior: NothingToDequeueBehavior
    private let workerPermissionProvider: WorkerPermissionProvider

    public init(
        bucketQueueFactory: BucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehavior,
        workerPermissionProvider: WorkerPermissionProvider)
    {
        self.bucketQueueFactory = bucketQueueFactory
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
        self.workerPermissionProvider = workerPermissionProvider
    }
    
    public func create() -> BalancingBucketQueue {
        let queue = BalancingBucketQueueImpl(
            bucketQueueFactory: bucketQueueFactory,
            nothingToDequeueBehavior: nothingToDequeueBehavior
        )
        return WorkerPermissionAwareBalancingBucketQueue(
            workerPermissionProvider: workerPermissionProvider,
            balancingBucketQueue: queue,
            nothingToDequeueBehavior: nothingToDequeueBehavior
        )
    }
}

