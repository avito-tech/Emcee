import Foundation
import WorkerAlivenessTracker
import Models

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    public func markWorkerAsAlive(workerId: WorkerId) {
        
    }
    
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId) {
        
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: WorkerId) {
        
    }
    
    public var workerAliveness = [WorkerId: WorkerAliveness]()
    
    public func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        return workerAliveness[workerId] ?? WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
    }
    
    public init() {}
}
