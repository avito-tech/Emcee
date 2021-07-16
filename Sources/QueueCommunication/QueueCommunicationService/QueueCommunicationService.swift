import QueueModels
import SocketModels
import Types

public protocol QueueCommunicationService {
    
    /// Determines which workers out of provided `workerIds` should be used by the queue described by `queueInfo`.
    /// - Parameters:
    ///   - queueInfo: A description of the queue which is requesing the utilizable subset of workers.
    ///   - workerIds: List of worker ids that queue is supposed to be using.
    ///   - completion: Callback with result.
    func workersToUtilize(
        queueInfo: QueueInfo,
        workerIds: Set<WorkerId>,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    )
    
    /// Queries a queue with a given address for its worker ids.
    /// Queue is using its set of workers when there is no need to share workers with other queues.
    /// - Parameters:
    ///   - queueAddress: Address of the queue which will be queried for its workers.
    ///   - completion: Callback with result.
    func queryQueueForWorkerIds(
        queueAddress: SocketAddress,
        completion: @escaping (Either<Set<WorkerId>, Error>) -> ()
    )
}
