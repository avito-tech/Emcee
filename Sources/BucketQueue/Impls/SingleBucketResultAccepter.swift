import BucketQueueModels
import Foundation
import EmceeLogging
import QueueModels
import RunnerModels
import TestHistoryTracker

public final class SingleBucketResultAccepter: BucketResultAccepter {
    private let bucketEnqueuer: BucketEnqueuer
    private let bucketQueueHolder: BucketQueueHolder
    private let testHistoryTracker: TestHistoryTracker
    
    public init(
        bucketEnqueuer: BucketEnqueuer,
        bucketQueueHolder: BucketQueueHolder,
        testHistoryTracker: TestHistoryTracker
    ) {
        self.bucketEnqueuer = bucketEnqueuer
        self.bucketQueueHolder = bucketQueueHolder
        self.testHistoryTracker = testHistoryTracker
    }
    
    public func accept(
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try bucketQueueHolder.performWithExclusiveAccess {
            Logger.debug("Validating result for \(bucketId) from \(workerId): \(testingResult)")
            
            guard let dequeuedBucket = previouslyDequeuedBucket(bucketId: bucketId, workerId: workerId) else {
                Logger.verboseDebug("Validation failed: no dequeued bucket for \(bucketId) \(workerId)")
                throw BucketQueueAcceptanceError.noDequeuedBucket(bucketId: bucketId, workerId: workerId)
            }
            
            let actualTestEntries = Set(testingResult.unfilteredResults.map { $0.testEntry })
            let expectedTestEntries = Set(dequeuedBucket.enqueuedBucket.bucket.testEntries)
            try reenqueueLostResults(
                expectedTestEntries: expectedTestEntries,
                actualTestEntries: actualTestEntries,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId
            )
            
            let acceptResult = try testHistoryTracker.accept(
                testingResult: testingResult,
                bucket: dequeuedBucket.enqueuedBucket.bucket,
                workerId: workerId
            )
            
            bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
            Logger.debug("Accepted result for \(dequeuedBucket.enqueuedBucket.bucket.bucketId) from \(workerId)")
            
            try bucketEnqueuer.enqueue(buckets: acceptResult.bucketsToReenqueue)
            
            return BucketQueueAcceptResult(
                dequeuedBucket: dequeuedBucket,
                testingResultToCollect: acceptResult.testingResult
            )
        }
    }
    
    private func reenqueueLostResults(
        expectedTestEntries: Set<TestEntry>,
        actualTestEntries: Set<TestEntry>,
        bucket: Bucket,
        workerId: WorkerId
    ) throws {
        let lostTestEntries = expectedTestEntries.subtracting(actualTestEntries)
        if !lostTestEntries.isEmpty {
            Logger.debug("Test result for \(bucket.bucketId) from \(workerId) contains lost test entries: \(lostTestEntries)")
            let lostResult = try testHistoryTracker.accept(
                testingResult: TestingResult(
                    testDestination: bucket.testDestination,
                    unfilteredResults: lostTestEntries.map { .lost(testEntry: $0) }
                ),
                bucket: bucket,
                workerId: workerId
            )
            
            try bucketEnqueuer.enqueue(buckets: lostResult.bucketsToReenqueue)
        }
    }
    
    private func previouslyDequeuedBucket(bucketId: BucketId, workerId: WorkerId) -> DequeuedBucket? {
        return bucketQueueHolder.allDequeuedBuckets.first {
            $0.enqueuedBucket.bucket.bucketId == bucketId && $0.workerId == workerId
        }
    }
}
