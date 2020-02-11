import Dispatch
import DistWorkerModels
import Models

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    )
}
