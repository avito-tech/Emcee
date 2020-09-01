import Foundation
import QueueModels
import WorkerCapabilitiesModels

public protocol WorkerCapabilitiesStorage {
    func set(workerCapabilities: Set<WorkerCapability>, forWorkerId: WorkerId)
    func workerCapabilities(forWorkerId: WorkerId) -> Set<WorkerCapability>
}
