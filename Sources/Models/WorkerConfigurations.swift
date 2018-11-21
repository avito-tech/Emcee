import Dispatch
import Foundation

public final class WorkerConfigurations {
    private let queue = DispatchQueue(label: "ru.avito.emcee.WorkerConfigurations.queue")
    private var workerIdToRunConfiguration = [String: WorkerConfiguration]()
    
    public init() {}
    
    public func add(workerId: String, configuration: WorkerConfiguration) {
        queue.sync { workerIdToRunConfiguration[workerId] = configuration }
    }
    
    public func workerConfiguration(workerId: String) -> WorkerConfiguration? {
        return queue.sync { workerIdToRunConfiguration[workerId] }
    }
}
