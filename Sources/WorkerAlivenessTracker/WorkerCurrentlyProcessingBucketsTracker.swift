import Foundation
import Logging
import Models

public final class WorkerCurrentlyProcessingBucketsTracker {
    
    private var values = [String: Set<BucketId>]()
    
    public init() {}
    
    public func bucketIdsBeingProcessedBy(workerId: String) -> Set<BucketId> {
        return values[workerId] ?? Set()
    }
    
    public func set(bucketIdsBeingProcessed bucketIds: Set<BucketId>, byWorkerId workerId: String) {
        if values[workerId] != bucketIds {
            values[workerId] = bucketIds
            Logger.verboseDebug("Worker \(workerId) is processing \(bucketIds.count) buckets: \(bucketIds)")
        }
    }
    
    public func append(bucketId: BucketId, workerId: String) {
        set(
            bucketIdsBeingProcessed: Set(bucketIdsBeingProcessedBy(workerId: workerId) + [bucketId]),
            byWorkerId: workerId
        )
    }
    
    public func resetBucketIdsBeingProcessedBy(workerId: String) {
        set(bucketIdsBeingProcessed: [], byWorkerId: workerId)
    }
}
