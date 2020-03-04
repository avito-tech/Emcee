import CountedSet
import Dispatch
import Foundation
import Models

public final class CurrentlyBeingProcessedBucketsTracker {
    
    private var bucketIds = CountedSet<BucketId>()
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.CurrentlyBeingProcessedBucketsTracker.syncQueue")
    public init() {}
    
    public func didFetch(bucketId: BucketId) {
        _ = syncQueue.sync {
            bucketIds.update(with: bucketId)
        }
    }
    
    public var bucketIdsBeingProcessed: Set<BucketId> {
        return syncQueue.sync {
            Set(bucketIds)
        }
    }
    
    public func didSendResults(bucketId: BucketId) {
        _ = syncQueue.sync {
            bucketIds.remove(bucketId)
        }
    }
}
