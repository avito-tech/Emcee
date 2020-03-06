import Dispatch
import DistWorkerModels
import Models

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        workerRestAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    )
}
