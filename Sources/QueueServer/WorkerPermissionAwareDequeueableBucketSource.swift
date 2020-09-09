import BalancingBucketQueue
import BucketQueue
import QueueCommunication
import QueueModels
import WorkerCapabilitiesModels

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

    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        guard workerPermissionProvider.utilizationPermissionForWorker(workerId: workerId) == .allowedToUtilize else {
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[])
        }

        return dequeueableBucketSource.dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
    }
}
