import BucketQueue
import Foundation
import QueueModels
import TestHelpers

open class FakeBucketResultAcceptorProvider: BucketResultAcceptorProvider {
    public var resultProvider: (BucketId, BucketResult, WorkerId) throws -> BucketQueueAcceptResult = { _, _, _ in
        throw ErrorForTestingPurposes()
    }
    
    public init() {}
    
    public func createBucketResultAcceptor(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketResultAcceptor {
        return FakeBucketResultAcceptor(
            bucketQueueHolder: bucketQueueHolder,
            resultProvider: resultProvider
        )
    }
}
