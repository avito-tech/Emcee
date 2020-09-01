import AtomicModels
import Foundation
import QueueModels
import Types
import WorkerCapabilitiesModels

public final class WorkerCapabilitiesStorageImpl: WorkerCapabilitiesStorage {
    private let storage = AtomicValue<MapWithCollection<WorkerId, WorkerCapability>>([:])
    
    public init() {}
    
    public func set(workerCapabilities: Set<WorkerCapability>, forWorkerId workerId: WorkerId) {
        storage.withExclusiveAccess {
            $0[workerId] = Array(workerCapabilities)
        }
    }
    
    public func workerCapabilities(forWorkerId workerId: WorkerId) -> Set<WorkerCapability> {
        Set(storage.withExclusiveAccess {
            $0[workerId]
        })
    }
}
