import QueueCommunication
import QueueCommunicationModels
import QueueModels

public class FakeWorkerPermissionProvider: WorkerPermissionProvider {
    public init() { }

    public var permission = WorkerUtilizationPermission.allowedToUtilize
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return permission
    }
}
