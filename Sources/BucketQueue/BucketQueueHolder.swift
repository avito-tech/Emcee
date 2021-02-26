import BucketQueueModels
import Foundation

public final class BucketQueueHolder {
    private var enqueuedBuckets = [EnqueuedBucket]()
    private var dequeuedBuckets = Set<DequeuedBucket>()

    private let syncQueue = DispatchQueue(label: "BucketQueueHolder.syncQueue")
    private let exclusiveAccessLock = NSRecursiveLock()

    public init() {}
    
    public func performWithExclusiveAccess<T>(
        work: () throws -> T
    ) rethrows -> T {
        exclusiveAccessLock.lock()
        defer {
            exclusiveAccessLock.unlock()
        }
        return try work()
    }
    
    public func removeAllEnqueuedBuckets() {
        syncQueue.sync {
            enqueuedBuckets.removeAll()
        }
    }
    
    public var allEnqueuedBuckets: [EnqueuedBucket] {
        syncQueue.sync { enqueuedBuckets }
    }
    
    public var allDequeuedBuckets: Set<DequeuedBucket> {
        syncQueue.sync { dequeuedBuckets }
    }
    
    public func remove(dequeuedBucket: DequeuedBucket) {
        syncQueue.sync {
            _ = dequeuedBuckets.remove(dequeuedBucket)
        }
    }
    
    public func insert(enqueuedBuckets: [EnqueuedBucket], position: Int) {
        syncQueue.sync {
            self.enqueuedBuckets.insert(contentsOf: enqueuedBuckets, at: position)
        }
    }
    
    public func replacePreviouslyEnqueuedBucket(withDequeuedBucket dequeuedBucket: DequeuedBucket) {
        syncQueue.sync {
            enqueuedBuckets.removeAll(where: { $0 == dequeuedBucket.enqueuedBucket })
            _ = dequeuedBuckets.insert(dequeuedBucket)
        }
    }
}
