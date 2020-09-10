import BucketQueue
import BucketQueueModels
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
    public let fixedDequeuedBucket: DequeuedBucket?
    public var removedAllEnqueuedBuckets = false
    
    public init(
        throwsOnAccept: Bool = false,
        fixedStuckBuckets: [StuckBucket] = [],
        fixedDequeuedBucket: DequeuedBucket? = nil
    ) {
        self.throwsOnAccept = throwsOnAccept
        self.fixedStuckBuckets = fixedStuckBuckets
        self.fixedDequeuedBucket = fixedDequeuedBucket
    }
    
    public var runningQueueState = RunningQueueState(
        enqueuedBucketCount: 0,
        enqueuedTests: [],
        dequeuedBucketCount: 0,
        dequeuedTests: [:]
    )
    
    public func enqueue(buckets: [Bucket]) {
        enqueuedBuckets.append(contentsOf: buckets)
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        return fixedDequeuedBucket
    }
    
    public func removeAllEnqueuedBuckets() {
        removedAllEnqueuedBuckets = true
    }
    
    public func accept(bucketId: BucketId, testingResult: TestingResult, workerId: WorkerId) throws -> BucketQueueAcceptResult {
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
                    workerId: workerId
                ),
                testingResultToCollect: testingResult
            )
        }
    }
    
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        return fixedStuckBuckets
    }
}
