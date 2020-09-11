import BucketQueueModels
import QueueModels
import WorkerCapabilitiesModels

public protocol DequeueableBucketSource {
    func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket?
}
