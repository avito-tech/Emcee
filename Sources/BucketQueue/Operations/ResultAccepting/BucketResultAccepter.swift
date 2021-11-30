import QueueModels

public protocol BucketResultAccepter {
    func accept(
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult
}
