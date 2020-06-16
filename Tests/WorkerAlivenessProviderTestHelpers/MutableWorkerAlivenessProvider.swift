import Foundation
import Models
import WorkerAlivenessProvider

public final class MutableWorkerAlivenessProvider: WorkerAlivenessProvider {
    
    public init() {}
    
    public var bucketIdByWorkerId = MapWithCollection<WorkerId, BucketId>()
    
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId) {
        bucketIdByWorkerId.append(key: workerId, elements: Array(bucketIdsBeingProcessed))
        workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: Set(bucketIdByWorkerId[workerId]))
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: WorkerId) {
        bucketIdByWorkerId.append(key: workerId, element: bucketId)
        workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: Set(bucketIdByWorkerId[workerId]))
    }
        
    public func didRegisterWorker(workerId: WorkerId) {
        bucketIdByWorkerId[workerId] = []
        workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
    }
    
    public func enableWorker(workerId: WorkerId) {
        workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: Set(bucketIdByWorkerId[workerId]))
    }
    
    public func disableWorker(workerId: WorkerId) {
        workerAliveness[workerId] = WorkerAliveness(status: .disabled, bucketIdsBeingProcessed: Set(bucketIdByWorkerId[workerId]))
    }
    
    public func setWorkerIsAlive(workerId: WorkerId) {
        workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: Set(bucketIdByWorkerId[workerId]))
    }
    
    public func setWorkerIsSilent(workerId: WorkerId) {
        workerAliveness[workerId] = WorkerAliveness(status: .silent, bucketIdsBeingProcessed: [])
    }
    
    public var workerAliveness = [WorkerId: WorkerAliveness]()
    
    public func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        if let aliveness = workerAliveness[workerId] {
            return aliveness
        } else {
            return WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
        }
    }
}
