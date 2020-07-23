import BucketQueue
import Foundation
import QueueModels
import QueueModelsTestHelpers
import WorkerCapabilitiesModels

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
        fixedDequeueResult: DequeueResult = .workerIsNotRegistered
        )
    {
        self.throwsOnAccept = throwsOnAccept
        self.fixedStuckBuckets = fixedStuckBuckets
        self.fixedDequeueResult = fixedDequeueResult
    }
    
    public var runningQueueState: RunningQueueState {
        return RunningQueueState(
            enqueuedTests: [],
            dequeuedTests: [:]
        )
    }
    
    public func enqueue(buckets: [Bucket]) {
        enqueuedBuckets.append(contentsOf: buckets)
    }
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return fixedPreviouslyDequeuedBucket
    }
    
    public func dequeueBucket(requestId: RequestId, workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
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
