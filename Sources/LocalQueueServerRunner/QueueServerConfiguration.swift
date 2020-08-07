import AutomaticTermination
import Deployer
import DistWorkerModels
import Foundation
import LoggingSetup
import QueueModels

public struct QueueServerConfiguration: Decodable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let checkAgainTimeInterval: TimeInterval
    public let queueServerDeploymentDestination: DeploymentDestination
    public let queueServerTerminationPolicy: AutomaticTerminationPolicy
    public let workerDeploymentDestinations: [DeploymentDestination]
    public let workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        checkAgainTimeInterval: TimeInterval,
        queueServerDeploymentDestination: DeploymentDestination,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        workerDeploymentDestinations: [DeploymentDestination],
        workerSpecificConfigurations: [WorkerId: WorkerSpecificConfiguration]
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.queueServerDeploymentDestination = queueServerDeploymentDestination
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.workerDeploymentDestinations = workerDeploymentDestinations
        self.workerSpecificConfigurations = workerSpecificConfigurations
    }
    
    public func workerConfiguration(
        workerSpecificConfiguration: WorkerSpecificConfiguration,
        payloadSignature: PayloadSignature
    ) -> WorkerConfiguration {
        return WorkerConfiguration(
            analyticsConfiguration: analyticsConfiguration,
            numberOfSimulators: workerSpecificConfiguration.numberOfSimulators,
            payloadSignature: payloadSignature
        )
    }
}
