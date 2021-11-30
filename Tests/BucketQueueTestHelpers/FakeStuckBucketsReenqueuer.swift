import BucketQueue
import BucketQueueModels
import Foundation
import TestHelpers
import Types

open class FakeStuckBucketsReenqueuer: StuckBucketsReenqueuer {
    public var result: () throws -> [StuckBucket]
    
    public init(
        result: @escaping () throws -> [StuckBucket] = {
            throw ErrorForTestingPurposes()
        }
    ) {
        self.result = result
    }
    
    public func reenqueueStuckBuckets() throws -> [StuckBucket] {
        try result()
    }
}
