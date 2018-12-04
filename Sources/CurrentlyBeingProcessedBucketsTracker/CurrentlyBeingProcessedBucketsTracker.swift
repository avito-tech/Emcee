import CountedSet
import Foundation

public final class CurrentlyBeingProcessedBucketsTracker {
    
    private var bucketIds = CountedSet<String>()
    public init() {}
    
    public func didFetch(bucketId: String) {
        bucketIds.update(with: bucketId)
    }
    
    public var bucketIdsBeingProcessed: Set<String> {
        return Set(bucketIds)
    }
    
    public func didObtainResult(bucketId: String) {
        bucketIds.remove(bucketId)
    }
}
