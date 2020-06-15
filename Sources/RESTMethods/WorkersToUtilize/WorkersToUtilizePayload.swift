import Deployer
import Models

public class WorkersToUtilizePayload: Codable {
    public let deployments: [DeploymentDestination]
    public let version: Version
    
    public init(
        deployments: [DeploymentDestination],
        version: Version
    ) {
        self.deployments = deployments
        self.version = version
    }
}
