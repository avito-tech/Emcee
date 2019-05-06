import Foundation

public protocol WorkerAlivenessProvider: class {
    /// Returns immediate snapshot of all worker aliveness statuses.
    var workerAliveness: [String: WorkerAliveness] { get }
    
    func alivenessForWorker(workerId: String) -> WorkerAliveness
    
    func markWorkerAsAlive(workerId: String)
    
    func set(bucketIdsBeingProcessed: Set<String>, workerId: String)
    func didDequeueBucket(bucketId: String, workerId: String)
}

public extension WorkerAlivenessProvider {
    var hasAnyAliveWorker: Bool {
        return workerAliveness.contains { _, value in
            value.status == .alive
        }
    }
    
    var aliveWorkerIds: [String] {
        return workerAliveness.filter { $0.value.status == .alive }.map { $0.key }
    }
}
