import Foundation
import QueueModels

public protocol WorkerConfigurations {
    
    /// Adds worker specific configuration for given `workerId`
    func add(workerId: WorkerId, configuration: WorkerConfiguration)
    
    /// Returns a worker specific configuration for given `workerId`, or `nil` if there is no known configuration.
    func workerConfiguration(workerId: WorkerId) -> WorkerConfiguration?
}
