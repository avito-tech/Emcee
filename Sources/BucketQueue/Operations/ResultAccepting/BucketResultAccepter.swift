import QueueModels

public protocol BucketResultAcceptor {
    func accept(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult
}
