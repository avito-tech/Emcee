import BucketQueue
import QueueCommunication
import QueueModels

public final class WorkerPermissionAwareDequeueableBucketSource: DequeueableBucketSource {
    private let dequeueableBucketSource: DequeueableBucketSource
    private let workerPermissionProvider: WorkerPermissionProvider
    private let nothingToDequeueBehavior: NothingToDequeueBehavior

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        nothingToDequeueBehavior: NothingToDequeueBehavior,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
        self.workerPermissionProvider = workerPermissionProvider
    }

    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        guard workerPermissionProvider.utilizationPermissionForWorker(workerId: workerId) == .allowedToUtilize else {
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[])
        }

        return dequeueableBucketSource.dequeueBucket(requestId: requestId, workerId: workerId)
    }

    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return dequeueableBucketSource.previouslyDequeuedBucket(requestId: requestId, workerId: workerId)
    }
}
