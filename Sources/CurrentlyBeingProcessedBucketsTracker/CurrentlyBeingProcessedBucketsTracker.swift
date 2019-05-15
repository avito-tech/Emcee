import CountedSet
import Dispatch
import Foundation

public final class CurrentlyBeingProcessedBucketsTracker {
    
    private var bucketIds = CountedSet<String>()
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.CurrentlyBeingProcessedBucketsTracker.syncQueue")
    public init() {}
    
    public func didFetch(bucketId: String) {
        _ = syncQueue.sync {
            bucketIds.update(with: bucketId)
        }
    }
    
    public var bucketIdsBeingProcessed: Set<String> {
        return syncQueue.sync {
            Set(bucketIds)
        }
    }
    
    public func didObtainResult(bucketId: String) {
        _ = syncQueue.sync {
            bucketIds.remove(bucketId)
        }
    }
}
