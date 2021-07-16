import Dispatch
import QueueCommunication
import QueueModels
import SocketModels
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
        queueInfo: QueueInfo,
        workerIds: Set<WorkerId>,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    ) {
        completionHandler(completion)
    }
    
    public var allQueriedQueueAddresses = [SocketAddress]()
    public var workersPerSocketAddress: [SocketAddress: Set<WorkerId>] = [:]
    public var deploymentDestinationsAsync = false
    public func queryQueueForWorkerIds(
        queueAddress: SocketAddress,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ())
    {
        allQueriedQueueAddresses.append(queueAddress)
        
        let workerIds = workersPerSocketAddress[queueAddress] ?? Set()
        
        if deploymentDestinationsAsync {
            callbackQueue.asyncAfter(deadline: .now() + 1) {
                completion(.success(workerIds))
            }
        } else {
            completion(.success(workerIds))
        }        
    }
}
