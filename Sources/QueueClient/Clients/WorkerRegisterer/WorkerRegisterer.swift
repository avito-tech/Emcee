import Dispatch
import DistWorkerModels
import QueueModels
import SocketModels
import Types
import WorkerCapabilitiesModels

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        workerCapabilities: Set<WorkerCapability>,
        workerRestAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    )
}
