public protocol WorkerUtilizationStatusPoller: WorkerPermissionProvider {
    func startPolling()
}
