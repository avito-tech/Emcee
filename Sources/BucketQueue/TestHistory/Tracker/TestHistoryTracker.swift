import Models

public protocol TestHistoryTracker {
    func bucketToDequeue(
        workerId: String,
        queue: [Bucket],
        aliveWorkers: @autoclosure () -> [String])
        -> Bucket?
    
    func accept(testingResult: TestingResult, bucket: Bucket, workerId: String) -> TestHistoryTrackerAcceptResult
}
