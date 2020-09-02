import QueueModels
import QueueCommunicationModels

public protocol WorkerPermissionProvider {
    func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission
}
