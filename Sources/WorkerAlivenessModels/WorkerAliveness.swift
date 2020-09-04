import Foundation
import QueueCommunicationModels
import QueueModels

public struct WorkerAliveness: Codable, Equatable, CustomStringConvertible {
    /// Shows if worker has started at all. `false` means worker process has never started or crashed before registering with Emcee queue.
    public let registered: Bool
    
    /// Shows if worker has been explicitly disabled.
    public let disabled: Bool
    
    /// Shows if queue has lost communication with a worker. This usually happens when worker crashes after running for a while or it is terminated (via signal, system reboot, etc).
    public let silent: Bool
    
    /// Indicates worker sharing feature status of this worker.
    public let workerUtilizationPermission: WorkerUtilizationPermission
    
    public let bucketIdsBeingProcessed: Set<BucketId>

    public init(
        registered: Bool,
        bucketIdsBeingProcessed: Set<BucketId>,
        disabled: Bool,
        silent: Bool,
        workerUtilizationPermission: WorkerUtilizationPermission
    ) {
        self.registered = registered
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
        self.disabled = disabled
        self.silent = silent
        self.workerUtilizationPermission = workerUtilizationPermission
    }
    
    /// Defines if worker is considered as utilizable unit.
    public var isInWorkingCondition: Bool {
        registered && !disabled && !silent && workerUtilizationPermission == .allowedToUtilize
    }
    
    public var description: String {
        return "\(registered ? "registered" : "not registered"), \(silent ? "silent" : "alive"), \(disabled ? "disabled" : "enabled"), \(workerUtilizationPermission == .allowedToUtilize ? "allowed to utilize" : "not utilizable"), processing bucket ids: \(bucketIdsBeingProcessed.sorted())"
    }
}
