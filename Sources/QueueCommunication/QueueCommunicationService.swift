import Deployer
import Models

public protocol QueueCommunicationService {
    func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    )
}
