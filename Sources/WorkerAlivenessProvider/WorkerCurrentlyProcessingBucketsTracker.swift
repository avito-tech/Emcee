import Foundation
import EmceeLogging
import QueueModels

public final class WorkerCurrentlyProcessingBucketsTracker {
    private let logger: ContextualLogger
    private var values = [WorkerId: Set<BucketId>]()
    
    public init(
        logger: ContextualLogger
    ) {
        self.logger = logger.forType(Self.self)
    }
    
    public func bucketIdsBeingProcessedBy(workerId: WorkerId) -> Set<BucketId> {
        return values[workerId] ?? Set()
    }
    
    public func set(bucketIdsBeingProcessed bucketIds: Set<BucketId>, byWorkerId workerId: WorkerId) {
        if values[workerId] != bucketIds {
            values[workerId] = bucketIds
            logger.debug("Worker \(workerId) is processing \(bucketIds.count) buckets: \(bucketIds)")
        }
    }
    
    public func append(bucketId: BucketId, workerId: WorkerId) {
        set(
            bucketIdsBeingProcessed: Set(bucketIdsBeingProcessedBy(workerId: workerId) + [bucketId]),
            byWorkerId: workerId
        )
    }
    
    public func resetBucketIdsBeingProcessedBy(workerId: WorkerId) {
        set(bucketIdsBeingProcessed: [], byWorkerId: workerId)
    }
}
