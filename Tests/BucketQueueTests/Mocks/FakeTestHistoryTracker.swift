import BucketQueue
import Foundation
import QueueModels

public final class FakeTestHistoryTracker: TestHistoryTracker {
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
