import Foundation
import QueueModels
import WorkerCapabilitiesModels

public protocol DequeueableBucketSource {
    func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket?
    func dequeueBucket(requestId: RequestId, workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult
}
