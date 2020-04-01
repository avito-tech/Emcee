import Models

public class DummyWorkerPermissionProvider: WorkerPermissionProvider {
    public init() { }
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return .allowedToUtilize
    }
}
