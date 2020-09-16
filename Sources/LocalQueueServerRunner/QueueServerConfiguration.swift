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
    
    private enum CodingKeys: String, CodingKey {
        case analyticsConfiguration
        case checkAgainTimeInterval
        case queueServerDeploymentDestination
        case queueServerTerminationPolicy
        case workerDeploymentDestinations
        case workerSpecificConfigurations
    }
     
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let analyticsConfiguration = try container.decode(AnalyticsConfiguration.self, forKey: .analyticsConfiguration)
        let checkAgainTimeInterval = try container.decode(TimeInterval.self, forKey: .checkAgainTimeInterval)
        let queueServerDeploymentDestination = try container.decode(DeploymentDestination.self, forKey: .queueServerDeploymentDestination)
        let queueServerTerminationPolicy = try container.decode(AutomaticTerminationPolicy.self, forKey: .queueServerTerminationPolicy)
        let workerDeploymentDestinations = try container.decode([DeploymentDestination].self, forKey: .workerDeploymentDestinations)
        let workerSpecificConfigurations = Dictionary(
            uniqueKeysWithValues: try container.decode(
                [String: WorkerSpecificConfiguration].self,
                forKey: .workerSpecificConfigurations
            ).map { key, value in
                (WorkerId(key), value)
            }
        )
        
        self.init(
            analyticsConfiguration: analyticsConfiguration,
            checkAgainTimeInterval: checkAgainTimeInterval,
            queueServerDeploymentDestination: queueServerDeploymentDestination,
            queueServerTerminationPolicy: queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            workerSpecificConfigurations: workerSpecificConfigurations
        )
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
