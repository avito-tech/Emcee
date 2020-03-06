import CountedSet
import Dispatch
import Foundation
import Models

public final class DefaultCurrentlyBeingProcessedBucketsTracker: CurrentlyBeingProcessedBucketsTracker {
    private var bucketIds = CountedSet<BucketId>()
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.CurrentlyBeingProcessedBucketsTracker.syncQueue")
    
    public init() {}
    
    public func willProcess(bucketId: BucketId) {
        _ = syncQueue.sync {
            bucketIds.update(with: bucketId)
        }
    }
    
    public func didProcess(bucketId: BucketId) {
        _ = syncQueue.sync {
            bucketIds.remove(bucketId)
        }
    }
    
    public var bucketIdsBeingProcessed: Set<BucketId> {
        return syncQueue.sync {
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
        return try syncQueue.sync {
            let tracker = InternalUnsafeTracker(bucketIds: bucketIds)
            defer { bucketIds = tracker.bucketIds }
            return try work(tracker)
        }
    }
}
