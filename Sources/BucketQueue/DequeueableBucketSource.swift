import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public protocol DequeueableBucketSource {
    func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult
}
