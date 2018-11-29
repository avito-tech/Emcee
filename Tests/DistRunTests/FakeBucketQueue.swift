import BucketQueue
import DistRun
import Foundation
import Models

class FakeBucketQueue: BucketQueue {
    struct AcceptanceError: Error {}
    
    var enqueuedBuckets = [Bucket]()
    let throwsOnAccept: Bool
    let fixedStuckBuckets: [StuckBucket]
    let fixedDequeueResult: DequeueResult
    
    public init(
        throwsOnAccept: Bool = false,
        fixedStuckBuckets: [StuckBucket] = [],
        fixedDequeueResult: DequeueResult = .workerBlocked)
    {
        self.throwsOnAccept = throwsOnAccept
        self.fixedStuckBuckets = fixedStuckBuckets
        self.fixedDequeueResult = fixedDequeueResult
    }
    
    var state: BucketQueueState {
        return BucketQueueState(enqueuedBucketCount: 0, dequeuedBucketCount: 0)
    }
    
    func enqueue(buckets: [Bucket]) {
        enqueuedBuckets.append(contentsOf: buckets)
    }
    
    func dequeueBucket(requestId: String, workerId: String) -> DequeueResult {
        return fixedDequeueResult
    }
    
    func accept(testingResult: TestingResult, requestId: String, workerId: String) throws -> BucketQueueAcceptResult {
        if throwsOnAccept {
            throw AcceptanceError()
        } else {
            return BucketQueueAcceptResult(testingResultToCollect: testingResult)
        }
    }
    
    func reenqueueStuckBuckets() -> [StuckBucket] {
        return fixedStuckBuckets
    }
}
