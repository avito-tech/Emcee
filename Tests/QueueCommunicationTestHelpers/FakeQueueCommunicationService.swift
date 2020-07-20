import Deployer
import DeployerTestHelpers
import Dispatch
import Models
import QueueCommunication
import QueueModels
import Types

public class FakeQueueCommunicationService: QueueCommunicationService {
    private let callbackQueue = DispatchQueue(
        label: "FakeQueueCommunicationService.callbackQueue",
        qos: .default,
        target: .global(qos: .userInitiated)
    )
    
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
    
    public var deploymentDestinationsCallPorts = [Port]()
    public var workersPerPort: [Port: [WorkerId]] = [:]
    public var deploymentDestinationsAsync = false
    public func deploymentDestinations(
        port: Port,
        completion: @escaping (Either<[DeploymentDestination], Error>) -> ())
    {
        deploymentDestinationsCallPorts.append(port)
        
        let deployents = (workersPerPort[port] ?? []).map { DeploymentDestinationFixtures().with(host: $0.value).build() }
        
        if deploymentDestinationsAsync {
            callbackQueue.asyncAfter(deadline: .now() + 1) {
                completion(.success(deployents))
            }
        } else {
            completion(.success(deployents))
        }        
    }
}
