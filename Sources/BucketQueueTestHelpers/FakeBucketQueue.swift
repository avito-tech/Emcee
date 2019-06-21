import BucketQueue
import Foundation
import Models
import ModelsTestHelpers

public class FakeBucketQueue: BucketQueue {
    
    public struct AcceptanceError: Error {}
    
    public var enqueuedBuckets = [Bucket]()
    public let throwsOnAccept: Bool
    public var acceptedResults = [TestingResult]()
    public let fixedStuckBuckets: [StuckBucket]
    public let fixedDequeueResult: DequeueResult
    public var fixedPreviouslyDequeuedBucket: DequeuedBucket?
    public var removedAllEnqueuedBuckets = false
    
    public init(
        throwsOnAccept: Bool = false,
        fixedStuckBuckets: [StuckBucket] = [],
        fixedDequeueResult: DequeueResult = .workerIsNotAlive
        )
    {
        self.throwsOnAccept = throwsOnAccept
        self.fixedStuckBuckets = fixedStuckBuckets
        self.fixedDequeueResult = fixedDequeueResult
    }
    
    public var runningQueueState: RunningQueueState {
        return RunningQueueState(
            enqueuedBucketCount: 0,
            dequeuedBucketCount: 0
        )
    }
    
    public func enqueue(buckets: [Bucket]) {
        enqueuedBuckets.append(contentsOf: buckets)
    }
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return fixedPreviouslyDequeuedBucket
    }
    
    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        return fixedDequeueResult
    }
    
    public func removeAllEnqueuedBuckets() {
        removedAllEnqueuedBuckets = true
    }
    
    public func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        if throwsOnAccept {
            throw AcceptanceError()
        } else {
            acceptedResults.append(testingResult)
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures.createBucket(),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: UUID().uuidString
                    ),
                    workerId: workerId,
                    requestId: requestId
                ),
                testingResultToCollect: testingResult
            )
        }
    }
    
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        return fixedStuckBuckets
    }
}
