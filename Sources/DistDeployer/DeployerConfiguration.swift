import Foundation
import Models

public final class DeployerConfiguration {
    public let deploymentDestinations: [DeploymentDestination]
    public let pluginLocations: [PluginLocation]
    public let queueServerHost: String
    public let queueServerPort: Int
    public let runId: String

    public init(
        deploymentDestinations: [DeploymentDestination],
        pluginLocations: [PluginLocation],
        queueServerHost: String,
        queueServerPort: Int,
        runId: String)
    {
        self.deploymentDestinations = deploymentDestinations
        self.pluginLocations = pluginLocations
        self.queueServerHost = queueServerHost
        self.queueServerPort = queueServerPort
        self.runId = runId
    }
}
