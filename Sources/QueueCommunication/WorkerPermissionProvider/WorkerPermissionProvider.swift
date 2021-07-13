import QueueModels
import QueueCommunicationModels

public protocol WorkerPermissionProvider {
    
    /// Returns an utilization status of the given worker id.
    /// - Parameter workerId: Worker id which utilization status should be obtained
    func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission
}
