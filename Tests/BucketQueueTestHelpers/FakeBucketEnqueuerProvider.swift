import BucketQueue
import Foundation

open class FakeBucketEnqueuerProvider: BucketEnqueuerProvider {
    public var fakeBucketEnqueuer = FakeBucketEnqueuer()
    
    public init() {}
    
    public func createBucketEnqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> BucketEnqueuer {
        fakeBucketEnqueuer
    }
}
