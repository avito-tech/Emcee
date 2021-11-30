import BucketQueue
import Foundation

open class FakeDequeueableBucketSourceProvider: DequeueableBucketSourceProvider {
    public var fakeDequeueableBucketSource = FakeDequeueableBucketSource()
    
    public init() {}
    
    public func createDequeueableBucketSource(
        bucketQueueHolder: BucketQueueHolder
    ) -> DequeueableBucketSource {
        fakeDequeueableBucketSource
    }
}
