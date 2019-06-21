import Foundation
import WorkerAlivenessTracker
import Models

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    public func markWorkerAsAlive(workerId: String) {
        
    }
    
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: String) {
        
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: String) {
        
    }
    
    public var workerAliveness = [String: WorkerAliveness]()
    
    public func alivenessForWorker(workerId: String) -> WorkerAliveness {
        return workerAliveness[workerId] ?? WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
    }
    
    public init() {}
}
