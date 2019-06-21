import Foundation
import Models

public protocol WorkerAlivenessProvider: class {
    /// Returns immediate snapshot of all worker aliveness statuses.
    var workerAliveness: [WorkerId: WorkerAliveness] { get }
    
    func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness
    
    func markWorkerAsAlive(workerId: WorkerId)
    
    func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId)
    func didDequeueBucket(bucketId: BucketId, workerId: WorkerId)
}

public extension WorkerAlivenessProvider {
    var hasAnyAliveWorker: Bool {
        return workerAliveness.contains { _, value in
            value.status == .alive
        }
    }
    
    var aliveWorkerIds: [WorkerId] {
        return workerAliveness.filter { $0.value.status == .alive }.map { $0.key }
    }
}
