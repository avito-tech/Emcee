import Deployer
import Models
import QueueModels
import Types

public protocol QueueCommunicationService {
    func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    )
    
    func deploymentDestinations(
        port: Port,
        completion: @escaping (Either<[DeploymentDestination], Error>) -> ()
    )
}
