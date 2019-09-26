import Dispatch
import Models
import RequestSender

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, RequestSenderError>) -> Void
    ) throws
}
