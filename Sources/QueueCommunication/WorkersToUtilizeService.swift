import Deployer
import Models

public protocol WorkersToUtilizeService {
    func workersToUtilize(deployments: [DeploymentDestination], version: Version) -> [WorkerId]
}
