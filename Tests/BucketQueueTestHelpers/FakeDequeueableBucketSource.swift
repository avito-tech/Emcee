import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class FakeDequeueableBucketSource: DequeueableBucketSource {
    public var dequeuedBucket: DequeuedBucket?
    
    public init(dequeuedBucket: DequeuedBucket? = nil) {
        self.dequeuedBucket = dequeuedBucket
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        return dequeuedBucket
    }
}
