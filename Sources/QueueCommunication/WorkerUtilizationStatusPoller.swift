public protocol WorkerUtilizationStatusPoller: WorkerPermissionProvider {
    func startPolling()
    func stopPollingAndRestoreDefaultConfig()
}
