import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import TestHistoryTracker

public final class FakeTestHistoryTracker: TestHistoryTracker {
    public init() {}
    
    public func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult {
        TestHistoryTrackerAcceptResult(bucketsToReenqueue: [], testingResult: testingResult)
    }
    
    public var validateWorkerIdsInWorkingCondition: ([WorkerId]) -> () = { _ in }
    
    public func bucketToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedBucket],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedBucket? {
        validateWorkerIdsInWorkingCondition(workerIdsInWorkingCondition())
        return nil
    }
}
