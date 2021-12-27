import AutomaticTermination
import Deployer
import DistWorkerModels
import EmceeExtensions
import Foundation
import MetricsExtensions
import LoggingSetup
import QueueModels

public struct QueueServerConfiguration: Codable {
    public let globalAnalyticsConfiguration: AnalyticsConfiguration?
    public let checkAgainTimeInterval: TimeInterval
    public let queueServerDeploymentDestinations: [DeploymentDestination]
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    public let workerDeploymentDestinations: [DeploymentDestination]
    public let defaultWorkerConfiguration: WorkerSpecificConfiguration?
    public let workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]
    public let workerStartMode: WorkerStartMode
    public let useOnlyIPv4: Bool
    
    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration?,
        checkAgainTimeInterval: TimeInterval,
        queueServerDeploymentDestinations: [DeploymentDestination],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        workerDeploymentDestinations: [DeploymentDestination],
        defaultWorkerSpecificConfiguration: WorkerSpecificConfiguration?,
        workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration],
        workerStartMode: WorkerStartMode,
        useOnlyIPv4: Bool
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.queueServerDeploymentDestinations = queueServerDeploymentDestinations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.workerDeploymentDestinations = workerDeploymentDestinations
        self.defaultWorkerConfiguration = defaultWorkerSpecificConfiguration
        self.workerSpecificConfigurations = workerSpecificConfigurations
        self.workerStartMode = workerStartMode
        self.useOnlyIPv4 = useOnlyIPv4
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
        case useOnlyIPv4
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let globalAnalyticsConfiguration = try container.decodeIfPresentExplaining(AnalyticsConfiguration.self, forKey: .globalAnalyticsConfiguration)
        let checkAgainTimeInterval = try container.decodeIfPresentExplaining(TimeInterval.self, forKey: .checkAgainTimeInterval) ?? QueueServerConfigurationDefaultValues.checkAgainTimeInterval
        let queueServerDeploymentDestinations = try container.decodeExplaining([DeploymentDestination].self, forKey: .queueServerDeploymentDestinations)
        let queueServerTerminationPolicy = try container.decodeIfPresentExplaining(AutomaticTerminationPolicy.self, forKey: .queueServerTerminationPolicy) ?? QueueServerConfigurationDefaultValues.queueServerTerminationPolicy
        let workerDeploymentDestinations = try container.decodeExplaining([DeploymentDestination].self, forKey: .workerDeploymentDestinations)
        let defaultWorkerSpecificConfiguration = try container.decodeIfPresentExplaining(WorkerSpecificConfiguration.self, forKey: .defaultWorkerConfiguration) ?? QueueServerConfigurationDefaultValues.defaultWorkerConfiguration
        let workerSpecificConfigurations = Dictionary(
            uniqueKeysWithValues: (
                try container.decodeIfPresentExplaining(
                    [String: WorkerSpecificConfiguration].self,
                    forKey: .workerSpecificConfigurations
                ) ?? [:]
            ).map { key, value in
                (WorkerId(key), value)
            }
        )
        let workerStartMode = try container.decodeIfPresentExplaining(WorkerStartMode.self, forKey: .workerStartMode) ?? QueueServerConfigurationDefaultValues.workerStartMode
        let useOnlyIPv4 = try container.decodeIfPresentExplaining(Bool.self, forKey: .useOnlyIPv4) ?? QueueServerConfigurationDefaultValues.useOnlyIPv4
        
        self.init(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            checkAgainTimeInterval: checkAgainTimeInterval,
            queueServerDeploymentDestinations: queueServerDeploymentDestinations,
            queueServerTerminationPolicy: queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            defaultWorkerSpecificConfiguration: defaultWorkerSpecificConfiguration,
            workerSpecificConfigurations: workerSpecificConfigurations,
            workerStartMode: workerStartMode,
            useOnlyIPv4: useOnlyIPv4
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(globalAnalyticsConfiguration, forKey: .globalAnalyticsConfiguration)
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
        try container.encode(useOnlyIPv4, forKey: .useOnlyIPv4)
    }
    
    public func workerConfiguration(
        workerSpecificConfiguration: WorkerSpecificConfiguration,
        payloadSignature: PayloadSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            numberOfSimulators: workerSpecificConfiguration.numberOfSimulators,
            payloadSignature: payloadSignature,
            maximumCacheSize: workerSpecificConfiguration.maximumCacheSize,
            maximumCacheTTL: workerSpecificConfiguration.maximumCacheTTL
        )
    }
}
