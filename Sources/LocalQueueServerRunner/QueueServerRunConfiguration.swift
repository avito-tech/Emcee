import AutomaticTermination
import Foundation
import Models
import SimulatorPool

public struct QueueServerRunConfiguration: Decodable {
    public let analyticsConfiguration: AnalyticsConfiguration
    
    /// Paths that are required to make things work
    public let auxiliaryResources: AuxiliaryResources

    /// Delay after workers should ask for a next bucket when all jobs are depleted
    public let checkAgainTimeInterval: TimeInterval
    
    /// A list of additional per-destination configurations.
    public let deploymentDestinationConfigurations: [DestinationConfiguration]
    
    /// Defines when queue server will terminate itself.
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    
    /// Period of time when workers should report their aliveness
    public let reportAliveInterval: TimeInterval
    
    public let workerDeploymentDestinations: [DeploymentDestination]

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        auxiliaryResources: AuxiliaryResources,
        checkAgainTimeInterval: TimeInterval,
        deploymentDestinationConfigurations: [DestinationConfiguration],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        reportAliveInterval: TimeInterval,
        workerDeploymentDestinations: [DeploymentDestination]
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.auxiliaryResources = auxiliaryResources
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.deploymentDestinationConfigurations = deploymentDestinationConfigurations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.reportAliveInterval = reportAliveInterval
        self.workerDeploymentDestinations = workerDeploymentDestinations
    }
    
    public func workerConfiguration(
        deploymentDestinationConfiguration: DestinationConfiguration,
        requestSignature: RequestSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            pluginUrls: auxiliaryResources.plugins.compactMap { $0.resourceLocation.url },
            reportAliveInterval: reportAliveInterval,
            requestSignature: requestSignature,
            testRunExecutionBehavior: testRunExecutionBehavior(
                deploymentDestinationConfiguration: deploymentDestinationConfiguration
            )
        )
    }
    
    private func testRunExecutionBehavior(
        deploymentDestinationConfiguration: DestinationConfiguration
    ) -> TestRunExecutionBehavior {
        return TestRunExecutionBehavior(
            numberOfSimulators: deploymentDestinationConfiguration.numberOfSimulators
        )
    }
}
