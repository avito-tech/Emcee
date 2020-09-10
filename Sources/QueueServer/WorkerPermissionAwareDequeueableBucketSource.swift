import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import QueueCommunication
import QueueModels
import WorkerCapabilitiesModels

public final class WorkerPermissionAwareDequeueableBucketSource: DequeueableBucketSource {
    private let dequeueableBucketSource: DequeueableBucketSource
    private let workerPermissionProvider: WorkerPermissionProvider

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.workerPermissionProvider = workerPermissionProvider
    }

    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        guard workerPermissionProvider.utilizationPermissionForWorker(workerId: workerId) == .allowedToUtilize else {
            return nil
        }

        return dequeueableBucketSource.dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
    }
}
