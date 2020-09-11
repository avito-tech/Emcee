import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import TestHistoryTracker

public final class FakeTestHistoryTracker: TestHistoryTracker {
    public init() {}
    
    public var acceptValidator: (TestingResult, Bucket, WorkerId) -> TestHistoryTrackerAcceptResult = { testingResult, _, _ in
        TestHistoryTrackerAcceptResult(
            bucketsToReenqueue: [],
            testingResult: testingResult
        )
    }
    
    public func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult {
        acceptValidator(testingResult, bucket, workerId)
    }
    
    public var validateWorkerIdsInWorkingCondition: ([WorkerId]) -> () = { _ in }
    public var bucketToDequeueProvider: (WorkerId, [EnqueuedBucket], [WorkerId]) -> EnqueuedBucket? = { _, _, _ in nil }
    
    public func bucketToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedBucket],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedBucket? {
        validateWorkerIdsInWorkingCondition(workerIdsInWorkingCondition())
        return bucketToDequeueProvider(workerId, queue, workerIdsInWorkingCondition())
    }
}
