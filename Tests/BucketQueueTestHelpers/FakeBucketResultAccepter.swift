import BucketQueue
import Foundation
import QueueModels

open class FakeBucketResultAccepter: BucketResultAccepter {
    public var bucketQueueHolder: BucketQueueHolder
    public var resultProvider: (BucketId, TestingResult, WorkerId) throws -> BucketQueueAcceptResult
    
    public init(
        bucketQueueHolder: BucketQueueHolder,
        resultProvider: @escaping (BucketId, TestingResult, WorkerId) throws -> BucketQueueAcceptResult
    ) {
        self.bucketQueueHolder = bucketQueueHolder
        self.resultProvider = resultProvider
    }
    
    public func accept(bucketId: BucketId, testingResult: TestingResult, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        try resultProvider(bucketId, testingResult, workerId)
    }
}
