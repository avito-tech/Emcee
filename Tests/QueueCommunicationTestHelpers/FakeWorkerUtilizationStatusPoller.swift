import Models
import QueueCommunication

public class FakeWorkerUtilizationStatusPoller: WorkerUtilizationStatusPoller {
    public init() { }
    
    public var startPollingCalled = false
    public func startPolling() {
        startPollingCalled = true
    }
    
    public var stopPollingCalled = false
    public func stopPollingAndRestoreDefaultConfig() {
        stopPollingCalled = true
    }    
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return .allowedToUtilize
    }
}
