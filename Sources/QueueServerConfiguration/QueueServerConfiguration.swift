import AutomaticTermination
import Deployer
import DistWorkerModels
import EmceeExtensions
import Foundation
import MetricsExtensions
import QueueModels

public struct QueueServerConfiguration: Codable {
    
    /// Global analytics. https://github.com/avito-tech/Emcee/releases/tag/12.0.0
    public let globalAnalyticsConfiguration: AnalyticsConfiguration
    
    /// How often workers should poll a queue for new buckets, in seconds. Recommended and default value is `30` seconds.
    public let checkAgainTimeInterval: TimeInterval
    
    /// Where queue should be deployed.
    public let queueServerDeploymentDestinations: [DeploymentDestination]
    
    /// How queue should terminate.
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    
    /// Where workers expected to be started.
    public let workerDeploymentDestinations: [DeploymentDestination]
    
    /// Default worker configuration, in case if you don't specify ones in `workerDeploymentDestinations`.
    public let defaultWorkerConfiguration: WorkerSpecificConfiguration?
    
    /// How workers are started.
    public let workerStartMode: WorkerStartMode
    
    /// Force communication only over IPv4. Sometimes IPv6 is enabled but not configured properly. In most cases pass `true` for ease of use.
    public let useOnlyIPv4: Bool
    
    /// What ports Emcee queue and workers should use. Default is `41000 ... 41010`.
    public let portRange: PortRange
    
    public init(
        globalAnalyticsConfiguration: AnalyticsConfiguration,
        checkAgainTimeInterval: TimeInterval,
        queueServerDeploymentDestinations: [DeploymentDestination],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        workerDeploymentDestinations: [DeploymentDestination],
        defaultWorkerSpecificConfiguration: WorkerSpecificConfiguration?,
        workerStartMode: WorkerStartMode,
        useOnlyIPv4: Bool,
        portRange: PortRange
    ) {
        self.globalAnalyticsConfiguration = globalAnalyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.queueServerDeploymentDestinations = queueServerDeploymentDestinations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.workerDeploymentDestinations = workerDeploymentDestinations
        self.defaultWorkerConfiguration = defaultWorkerSpecificConfiguration
        self.workerStartMode = workerStartMode
        self.useOnlyIPv4 = useOnlyIPv4
        self.portRange = portRange
    }
    
    private enum CodingKeys: String, CodingKey {
        case globalAnalyticsConfiguration
        case checkAgainTimeInterval
        case queueServerDeploymentDestinations
        case queueServerTerminationPolicy
        case workerDeploymentDestinations
        case defaultWorkerConfiguration
        case workerStartMode
        case useOnlyIPv4
        case portRange
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let globalAnalyticsConfiguration = try container.decodeIfPresentExplaining(AnalyticsConfiguration.self, forKey: .globalAnalyticsConfiguration) ?? QueueServerConfigurationDefaultValues.globalAnalyticsConfiguration
        let checkAgainTimeInterval = try container.decodeIfPresentExplaining(TimeInterval.self, forKey: .checkAgainTimeInterval) ?? QueueServerConfigurationDefaultValues.checkAgainTimeInterval
        let queueServerDeploymentDestinations = try container.decodeExplaining([DeploymentDestination].self, forKey: .queueServerDeploymentDestinations)
        let queueServerTerminationPolicy = try container.decodeIfPresentExplaining(AutomaticTerminationPolicy.self, forKey: .queueServerTerminationPolicy) ?? QueueServerConfigurationDefaultValues.queueServerTerminationPolicy
        let workerDeploymentDestinations = try container.decodeExplaining([DeploymentDestination].self, forKey: .workerDeploymentDestinations)
        let defaultWorkerSpecificConfiguration = try container.decodeIfPresentExplaining(WorkerSpecificConfiguration.self, forKey: .defaultWorkerConfiguration) ?? WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
        let workerStartMode = try container.decodeIfPresentExplaining(WorkerStartMode.self, forKey: .workerStartMode) ?? QueueServerConfigurationDefaultValues.workerStartMode
        let useOnlyIPv4 = try container.decodeIfPresentExplaining(Bool.self, forKey: .useOnlyIPv4) ?? QueueServerConfigurationDefaultValues.useOnlyIPv4
        let portRange = try container.decodeIfPresentExplaining(PortRange.self, forKey: .portRange) ?? QueueServerConfigurationDefaultValues.defaultQueuePortRange
        
        self.init(
            globalAnalyticsConfiguration: globalAnalyticsConfiguration,
            checkAgainTimeInterval: checkAgainTimeInterval,
            queueServerDeploymentDestinations: queueServerDeploymentDestinations,
            queueServerTerminationPolicy: queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            defaultWorkerSpecificConfiguration: defaultWorkerSpecificConfiguration,
            workerStartMode: workerStartMode,
            useOnlyIPv4: useOnlyIPv4,
            portRange: portRange
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
        try container.encode(workerStartMode, forKey: .workerStartMode)
        try container.encode(useOnlyIPv4, forKey: .useOnlyIPv4)
        try container.encode(portRange, forKey: .portRange)
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
            maximumCacheTTL: workerSpecificConfiguration.maximumCacheTTL,
            portRange: portRange
        )
    }
}
