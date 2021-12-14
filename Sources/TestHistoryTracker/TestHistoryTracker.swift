import BucketQueueModels
import QueueModels
import RunnerModels
import TestHistoryModels

public protocol TestHistoryTracker {
    
    /// Selects the most appropriate payload to be dequeued from the provided queue of payloads.
    /// Provided `workerId` may have failed all payloads in the `queue` in the past, or it may be not in appropriate state (e.g. silent).
    /// This may result in returning `nil` value.
    func enqueuedPayloadToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedRunIosTestsPayload],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedRunIosTestsPayload?
    
    /// Associates the provided result for the given `bucketId`, indicating that results are coming from `workerId`.
    /// - Note: `numberOfRetries` is ORIGINAL retry count for tests in the bucket with `bucketId`. Do not decrement this value.
    func accept(
        testingResult: TestingResult,
        bucketId: BucketId,
        numberOfRetries: UInt,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult
    
    func willReenqueuePreviouslyFailedTests(
        whichFailedUnderBucketId oldBucketId: BucketId,
        underNewBucketIds testEntryByBucketId: [BucketId: TestEntry]
    )
}
