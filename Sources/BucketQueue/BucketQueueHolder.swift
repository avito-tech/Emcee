import BucketQueueModels
import EmceeExtensions
import Foundation
import QueueModels

/// Defines a mutable state of a single bucket queue. All mutation should happen through `SinglaBucketQueueXXX` impls.
public final class BucketQueueHolder {
    private var enqueuedBuckets = [EnqueuedBucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()

    private let accessLock = NSLock()
    private let exclusiveAccessLock = NSRecursiveLock()

    public init() {}
    
    public func performWithExclusiveAccess<T>(
        work: () throws -> T
    ) rethrows -> T {
        try exclusiveAccessLock.whileLocked(work)
    }
    
    public func removeAllEnqueuedBuckets() {
        accessLock.whileLocked {
            enqueuedBuckets.removeAll()
        }
    }
    
    public var allEnqueuedBuckets: [EnqueuedBucket] {
        accessLock.whileLocked { enqueuedBuckets }
    }
    
    public var allDequeuedBuckets: Set<DequeuedBucket> {
        accessLock.whileLocked { dequeuedBuckets }
    }
    
    public func enqueuedBucket(bucketId: BucketId) -> EnqueuedBucket? {
        accessLock.whileLocked {
            enqueuedBuckets.first { enqueuedBucket in
                enqueuedBucket.bucket.bucketId == bucketId
            }
        }
    }
    
    public func remove(dequeuedBucket: DequeuedBucket) {
        accessLock.whileLocked {
            _ = dequeuedBuckets.remove(dequeuedBucket)
        }
    }
    
    public func insert(enqueuedBuckets: [EnqueuedBucket], position: Int) {
        accessLock.whileLocked {
            self.enqueuedBuckets.insert(contentsOf: enqueuedBuckets, at: position)
        }
    }
    
    public func replacePreviouslyEnqueuedBucket(withDequeuedBucket dequeuedBucket: DequeuedBucket) {
        accessLock.whileLocked {
            enqueuedBuckets.removeAll(where: { $0 == dequeuedBucket.enqueuedBucket })
            _ = dequeuedBuckets.insert(dequeuedBucket)
        }
    }
}
