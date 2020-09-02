import QueueModels

public protocol TestHistoryTracker {
    func bucketToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedBucket],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedBucket?
    
    func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult
}
