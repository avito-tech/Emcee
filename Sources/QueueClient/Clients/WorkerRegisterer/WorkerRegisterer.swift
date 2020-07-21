import Dispatch
import DistWorkerModels
import QueueModels
import SocketModels
import Types

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        workerRestAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    )
}
