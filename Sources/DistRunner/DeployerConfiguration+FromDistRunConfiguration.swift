import Foundation
import Models
import DistDeployer

public extension DeployerConfiguration {
    public static func from(
        distRunConfiguration: DistRunConfiguration,
        queueServerHost: String,
        queueServerPort: Int)
        -> DeployerConfiguration
    {
        return DeployerConfiguration(
            deploymentDestinations: distRunConfiguration.destinations,
            pluginLocations: distRunConfiguration.auxiliaryResources.plugins,
            queueServerHost: queueServerHost,
            queueServerPort: queueServerPort,
            runId: distRunConfiguration.runId
        )
    }
}
