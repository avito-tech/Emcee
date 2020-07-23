import BucketQueue
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class FakeDequeueableBucketSource: DequeueableBucketSource {
    public var dequeueResult: DequeueResult
    public var previouslyDequeuedBucket: DequeuedBucket?
    
    public init(dequeueResult: DequeueResult = .queueIsEmpty, previouslyDequeuedBucket: DequeuedBucket? = nil) {
        self.dequeueResult = dequeueResult
        self.previouslyDequeuedBucket = previouslyDequeuedBucket
    }
    
    public func dequeueBucket(requestId: RequestId, workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        return dequeueResult
    }
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return previouslyDequeuedBucket
    }
}
