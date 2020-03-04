import Dispatch
import DistWorkerModels
import Models

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        workerRestPort: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    )
}
