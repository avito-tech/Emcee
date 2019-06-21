import Models

public protocol TestHistoryTracker {
    func bucketToDequeue(
        workerId: String,
        queue: [EnqueuedBucket],
        aliveWorkers: @autoclosure () -> [String])
        -> EnqueuedBucket?
    
    func accept(
        testingResult: TestingResult,
        bucket: Bucket,
        workerId: String
    ) throws -> TestHistoryTrackerAcceptResult
}
