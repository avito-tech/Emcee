import CLTExtensions
import Dispatch
import Foundation
import QueueModels

public final class WorkerConfigurationsWithDefaultConfiguration: WorkerConfigurations {
    private let defaultConfiguration: WorkerConfiguration?
    private let wrapped: WorkerConfigurations
    
    public init(
        defaultConfiguration: WorkerConfiguration,
        wrapped: WorkerConfigurations
    ) {
        self.defaultConfiguration = defaultConfiguration
        self.wrapped = wrapped
    }
    
    public func add(workerId: WorkerId, configuration: WorkerConfiguration) {
        wrapped.add(workerId: workerId, configuration: configuration)
    }
    
    public func workerConfiguration(workerId: WorkerId) -> WorkerConfiguration? {
        wrapped.workerConfiguration(workerId: workerId) ?? defaultConfiguration
    }
}
