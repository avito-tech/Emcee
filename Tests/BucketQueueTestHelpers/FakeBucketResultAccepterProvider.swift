import BucketQueue
import Foundation
import QueueModels
import TestHelpers

open class FakeBucketResultAccepterProvider: BucketResultAccepterProvider {
    public var resultProvider: (BucketId, TestingResult, WorkerId) throws -> BucketQueueAcceptResult = { _, _, _ in
        throw ErrorForTestingPurposes()
    }
    
    public init() {}
    
    public func createBucketResultAccepter(bucketQueueHolder: BucketQueueHolder) -> BucketResultAccepter {
        return FakeBucketResultAccepter(
            bucketQueueHolder: bucketQueueHolder,
            resultProvider: resultProvider
        )
    }
}
