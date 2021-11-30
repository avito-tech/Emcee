import BucketQueue
import Foundation

open class FakeStuckBucketsReenqueuerProvider: StuckBucketsReenqueuerProvider {
    public var fakeStuckBucketsReenqueuer = FakeStuckBucketsReenqueuer()
    
    public init() {}
    
    public func createStuckBucketsReenqueuer(
        bucketQueueHolder: BucketQueueHolder
    ) -> StuckBucketsReenqueuer {
        fakeStuckBucketsReenqueuer
    }
}
