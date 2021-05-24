import CLTExtensions
import Dispatch
import Foundation
import QueueModels

public final class WorkerConfigurations {
    private let lock = NSLock()
    private var workerIdToRunConfiguration = [WorkerId: WorkerConfiguration]()
    
    public init() {}
    
    public func add(workerId: WorkerId, configuration: WorkerConfiguration) {
        lock.whileLocked { workerIdToRunConfiguration[workerId] = configuration }
    }
    
    public func workerConfiguration(workerId: WorkerId) -> WorkerConfiguration? {
        lock.whileLocked { workerIdToRunConfiguration[workerId] }
    }
    
    public var workerIds: Set<WorkerId> {
        return Set(lock.whileLocked{ workerIdToRunConfiguration.keys })
    }
}
