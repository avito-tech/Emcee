import Deployer
import Models
import QueueCommunication

public class FakeQueueCommunicationService: QueueCommunicationService {
    public init() { }
    
    public typealias CompletionType = (Either<Set<WorkerId>, Error>) -> ()
    public var completionHandler: (CompletionType) -> () = { completion in
        completion(Either(Set<WorkerId>()))
    }
     
    public func workersToUtilize(
        deployments: [DeploymentDestination],
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        completionHandler(completion)
    }
}
