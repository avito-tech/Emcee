import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class FakeDequeueableBucketSource: DequeueableBucketSource {
    public var dequeueResult: DequeueResult
    
    public init(dequeueResult: DequeueResult = .queueIsEmpty) {
        self.dequeueResult = dequeueResult
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        return dequeueResult
    }
}
