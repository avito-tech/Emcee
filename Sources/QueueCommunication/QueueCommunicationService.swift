import Deployer
import QueueModels
import SocketModels
import Types

public protocol QueueCommunicationService {
    func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    )
    
    func deploymentDestinations(
        port: SocketModels.Port,
        completion: @escaping (Either<[DeploymentDestination], Error>) -> ()
    )
}
