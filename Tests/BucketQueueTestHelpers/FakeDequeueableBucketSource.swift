import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

open class FakeDequeueableBucketSource: DequeueableBucketSource {
    public var result: (Set<WorkerCapability>, WorkerId) -> DequeuedBucket?
    
    public init(
        result: @escaping (Set<WorkerCapability>, WorkerId) -> DequeuedBucket? = { _, _ in nil }
    ) {
        self.result = result
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        result(workerCapabilities, workerId)
    }
}
