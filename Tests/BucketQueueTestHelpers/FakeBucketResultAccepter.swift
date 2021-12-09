import BucketQueue
import Foundation
import QueueModels

open class FakeBucketResultAcceptor: BucketResultAcceptor {
    public var bucketQueueHolder: BucketQueueHolder
    public var resultProvider: (BucketId, BucketResult, WorkerId) throws -> BucketQueueAcceptResult
    
    public init(
        bucketQueueHolder: BucketQueueHolder,
        resultProvider: @escaping (BucketId, BucketResult, WorkerId) throws -> BucketQueueAcceptResult
    ) {
        self.bucketQueueHolder = bucketQueueHolder
        self.resultProvider = resultProvider
    }
    
    public func accept(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        try resultProvider(bucketId, bucketResult, workerId)
    }
}
