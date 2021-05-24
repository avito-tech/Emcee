import Foundation
import QueueModels
import WorkerAlivenessModels

public protocol WorkerAlivenessProvider: AnyObject {
    /// Returns immediate snapshot of all worker aliveness statuses.
    var workerAliveness: [WorkerId: WorkerAliveness] { get }
    
    func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness
    
    func willDequeueBucket(workerId: WorkerId)
    func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId)
    func didDequeueBucket(bucketId: BucketId, workerId: WorkerId)
    func bucketIdsBeingProcessed(workerId: WorkerId) -> Set<BucketId>
    
    func isWorkerRegistered(workerId: WorkerId) -> Bool
    func didRegisterWorker(workerId: WorkerId)
    
    func enableWorker(workerId: WorkerId)
    func disableWorker(workerId: WorkerId)
    func isWorkerEnabled(workerId: WorkerId) -> Bool
    
    func setWorkerIsSilent(workerId: WorkerId)
    func isWorkerSilent(workerId: WorkerId) -> Bool
}

public extension WorkerAlivenessProvider {
    var hasAnyAliveWorker: Bool {
        !workerAliveness.filter { $0.value.silent == false }.map { $0.key }.isEmpty
    }
    
    var workerIdsInWorkingCondition: [WorkerId] {
        return workerAliveness.filter { $0.value.isInWorkingCondition }.map { $0.key }
    }
}
