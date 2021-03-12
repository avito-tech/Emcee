import CountedSet
import Dispatch
import Extensions
import Foundation
import QueueModels

public final class DefaultCurrentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker {
    private var bucketIds = CountedSet<BucketId>()
    private let lock = NSLock()
    
    public init() {}
    
    public func willProcess(bucketId: BucketId) {
        lock.whileLocked {
            _ = bucketIds.update(with: bucketId)
        }
    }
    
    public func didProcess(bucketId: BucketId) {
        lock.whileLocked {
            _ = bucketIds.remove(bucketId)
        }
    }
    
    public var bucketIdsBeingProcessed: Set<BucketId> {
        lock.whileLocked {
            Set(bucketIds)
        }
    }
    
    private class InternalUnsafeTracker: CurrentlyBeingProcessedBucketsTracker {
        var bucketIds = CountedSet<BucketId>()
        
        init(bucketIds: CountedSet<BucketId>) {
            self.bucketIds = bucketIds
        }
        
        func willProcess(bucketId: BucketId) {
            bucketIds.update(with: bucketId)
        }
        
        func didProcess(bucketId: BucketId) {
            bucketIds.remove(bucketId)
        }
        
        var bucketIdsBeingProcessed: Set<BucketId> {
            Set(bucketIds)
        }
    }
    
    public func perform<T>(work: (CurrentlyBeingProcessedBucketsTracker) throws -> T) rethrows -> T {
        try lock.whileLocked {
            let tracker = InternalUnsafeTracker(bucketIds: bucketIds)
            defer { bucketIds = tracker.bucketIds }
            return try work(tracker)
        }
    }
}
