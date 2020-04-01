import Models

public enum WorkerUtilizationPermission {
    case allowedToUtilize
    case notAllowedToUtilize
}

public protocol WorkerPermissionProvider {
    func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission
}
