import Models
import QueueCommunication

class FakeWorkerPermissionProvider: WorkerPermissionProvider {

    var permission = WorkerUtilizationPermission.allowedToUtilize
    func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return permission
    }
}
