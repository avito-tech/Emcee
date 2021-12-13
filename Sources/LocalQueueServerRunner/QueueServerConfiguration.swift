import AutomaticTermination
import Deployer
import DistWorkerModels
import Foundation
import MetricsExtensions
import LoggingSetup
import QueueModels

public struct QueueServerConfiguration: Codable {
    public let globalAnalyticsConfiguration: AnalyticsConfiguration
    public let checkAgainTimeInterval: TimeInterval
    public let queueServerDeploymentDestinations: [DeploymentDestination]
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    public let workerDeploymentDestinations: [DeploymentDestination]
    public let defaultWorkerConfiguration: WorkerSpecificConfiguration?
    public let workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]
    public let workerStartMode: WorkerStartMode
    
    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration,
        checkAgainTimeInterval: TimeInterval,
        queueServerDeploymentDestinations: [DeploymentDestination],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        workerDeploymentDestinations: [DeploymentDestination],
        defaultWorkerSpecificConfiguration: WorkerSpecificConfiguration?,
        workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration],
        workerStartMode: WorkerStartMode
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.queueServerDeploymentDestinations = queueServerDeploymentDestinations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.workerDeploymentDestinations = workerDeploymentDestinations
        self.defaultWorkerConfiguration = defaultWorkerSpecificConfiguration
        self.workerSpecificConfigurations = workerSpecificConfigurations
        self.workerStartMode = workerStartMode
    }
    
    private enum CodingKeys: String, CodingKey {
        case globalAnalyticsConfiguration
        case checkAgainTimeInterval
        case queueServerDeploymentDestinations
        case queueServerTerminationPolicy
        case workerDeploymentDestinations
        case defaultWorkerConfiguration
        case workerSpecificConfigurations
        case workerStartMode
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let globalAnalyticsConfiguration = try container.decode(AnalyticsConfiguration.self, forKey: .globalAnalyticsConfiguration)
        let checkAgainTimeInterval = try container.decode(TimeInterval.self, forKey: .checkAgainTimeInterval)
        let queueServerDeploymentDestinations = try container.decode([DeploymentDestination].self, forKey: .queueServerDeploymentDestinations)
        let queueServerTerminationPolicy = try container.decode(AutomaticTerminationPolicy.self, forKey: .queueServerTerminationPolicy)
        let workerDeploymentDestinations = try container.decode([DeploymentDestination].self, forKey: .workerDeploymentDestinations)
        let defaultWorkerSpecificConfiguration = try container.decodeIfPresent(WorkerSpecificConfiguration.self, forKey: .defaultWorkerConfiguration)
        let workerSpecificConfigurations = Dictionary(
            uniqueKeysWithValues: try container.decode(
                [String: WorkerSpecificConfiguration].self,
                forKey: .workerSpecificConfigurations
            ).map { key, value in
                (WorkerId(key), value)
            }
        )
        let workerStartMode = try container.decodeIfPresent(WorkerStartMode.self, forKey: .workerStartMode) ?? .queueStartsItsWorkersOverSshAndLaunchd
        
        self.init(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            checkAgainTimeInterval: checkAgainTimeInterval,
            queueServerDeploymentDestinations: queueServerDeploymentDestinations,
            queueServerTerminationPolicy: queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            defaultWorkerSpecificConfiguration: defaultWorkerSpecificConfiguration,
            workerSpecificConfigurations: workerSpecificConfigurations,
            workerStartMode: workerStartMode
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(globalAnalyticsConfiguration, forKey: .globalAnalyticsConfiguration)
        try container.encode(checkAgainTimeInterval, forKey: .checkAgainTimeInterval)
        try container.encode(queueServerDeploymentDestinations, forKey: .queueServerDeploymentDestinations)
        try container.encode(queueServerTerminationPolicy, forKey: .queueServerTerminationPolicy)
        try container.encode(workerDeploymentDestinations, forKey: .workerDeploymentDestinations)
        try container.encodeIfPresent(defaultWorkerConfiguration, forKey: .defaultWorkerConfiguration)
        try container.encode(
            Dictionary(
                uniqueKeysWithValues: workerSpecificConfigurations.map { item in
                    (item.key.value, item.value)
                }
            ),
            forKey: .workerSpecificConfigurations
        )
        try container.encode(workerStartMode, forKey: .workerStartMode)
    }
    
    public func workerConfiguration(
        workerSpecificConfiguration: WorkerSpecificConfiguration,
        payloadSignature: PayloadSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            numberOfSimulators: workerSpecificConfiguration.numberOfSimulators,
            payloadSignature: payloadSignature
        )
    }
}
