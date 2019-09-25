import Foundation
import WorkerAlivenessProvider
import Models

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId) {
        
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: WorkerId) {
        
    }
    
    public func blockWorker(workerId: WorkerId) {
        
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        
    }
    
    public var workerAliveness = [WorkerId: WorkerAliveness]()
    
    public func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        return workerAliveness[workerId] ?? WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
    }
    
    public init() {}
}
