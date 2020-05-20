import BucketQueue
import Foundation
import Models

public final class FakeDequeueableBucketSource: DequeueableBucketSource {
    public var dequeueResult: DequeueResult
    public var previouslyDequeuedBucket: DequeuedBucket?
    
    public init(dequeueResult: DequeueResult = .queueIsEmpty, previouslyDequeuedBucket: DequeuedBucket? = nil) {
        self.dequeueResult = dequeueResult
        self.previouslyDequeuedBucket = previouslyDequeuedBucket
    }
    
    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        return dequeueResult
    }
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return previouslyDequeuedBucket
    }
}
