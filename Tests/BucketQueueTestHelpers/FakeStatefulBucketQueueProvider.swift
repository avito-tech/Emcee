import BucketQueue
import Foundation

open class FakeStatefulBucketQueueProvider: StatefulBucketQueueProvider {
    public var fakeStatefulBucketQueue = FakeStatefulBucketQueue()
    
    public init() {}
    
    public func createStatefulBucketQueue(
        bucketQueueHolder: BucketQueueHolder
    ) -> StatefulBucketQueue {
        fakeStatefulBucketQueue
    }
}
