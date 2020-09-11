import BucketQueueModels
import Foundation
import Logging

public final class BucketQueueHolder {
    private var enqueuedBuckets = [EnqueuedBucket]() {
        didSet {
            Logger.debug("Updated enqueued buckets count: \(enqueuedBuckets.count)")
        }
    }
    private var dequeuedBuckets = Set<DequeuedBucket>() {
        didSet {
            Logger.debug("Updated dequeued buckets count: \(dequeuedBuckets.count)")
        }
    }

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
            Logger.debug("Removing all enqueued buckets (\(enqueuedBuckets.count) items)")
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
