import AutomaticTermination
import Deployer
import DistWorkerModels
import Foundation
import LoggingSetup
import Models

public struct QueueServerRunConfiguration: Decodable {
    public let analyticsConfiguration: AnalyticsConfiguration

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
        checkAgainTimeInterval: TimeInterval,
        deploymentDestinationConfigurations: [DestinationConfiguration],
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        reportAliveInterval: TimeInterval,
        workerDeploymentDestinations: [DeploymentDestination]
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.deploymentDestinationConfigurations = deploymentDestinationConfigurations
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.reportAliveInterval = reportAliveInterval
        self.workerDeploymentDestinations = workerDeploymentDestinations
    }
    
    public func workerConfiguration(
        deploymentDestinationConfiguration: DestinationConfiguration,
        payloadSignature: PayloadSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            numberOfSimulators: deploymentDestinationConfiguration.numberOfSimulators,
            payloadSignature: payloadSignature,
            reportAliveInterval: reportAliveInterval
        )
    }
}
