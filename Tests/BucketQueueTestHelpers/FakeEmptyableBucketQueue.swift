import BucketQueue
import Foundation

open class FakeEmptyableBucketQueue: EmptyableBucketQueue {
    public var onRemoveAllEnqueuedBuckets: () -> ()
    
    public init(onRemoveAllEnqueuedBuckets: @escaping () -> ()) {
        self.onRemoveAllEnqueuedBuckets = onRemoveAllEnqueuedBuckets
    }
    
    public func removeAllEnqueuedBuckets() {
        onRemoveAllEnqueuedBuckets()
    }
}
