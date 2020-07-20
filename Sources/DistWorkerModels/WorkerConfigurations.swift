import Dispatch
import Models
import Foundation
import QueueModels

public final class WorkerConfigurations {
    private let queue = DispatchQueue(label: "WorkerConfigurations.queue")
    private var workerIdToRunConfiguration = [WorkerId: WorkerConfiguration]()
    
    public init() {}
    
    public func add(workerId: WorkerId, configuration: WorkerConfiguration) {
        queue.sync { workerIdToRunConfiguration[workerId] = configuration }
    }
    
    public func workerConfiguration(workerId: WorkerId) -> WorkerConfiguration? {
        return queue.sync { workerIdToRunConfiguration[workerId] }
    }
    
    public var workerIds: Set<WorkerId> {
        return Set(workerIdToRunConfiguration.keys)
    }
}
