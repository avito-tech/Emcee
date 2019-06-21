import Dispatch
import Foundation

public final class WorkerConfigurations {
    private let queue = DispatchQueue(label: "ru.avito.emcee.WorkerConfigurations.queue")
    private var workerIdToRunConfiguration = [WorkerId: WorkerConfiguration]()
    
    public init() {}
    
    public func add(workerId: WorkerId, configuration: WorkerConfiguration) {
        queue.sync { workerIdToRunConfiguration[workerId] = configuration }
    }
    
    public func workerConfiguration(workerId: WorkerId) -> WorkerConfiguration? {
        return queue.sync { workerIdToRunConfiguration[workerId] }
    }
}
