import Models
import RequestSender

public protocol WorkerRegisterer {
    func registerWithServer(
        workerId: WorkerId,
        completion: @escaping (Either<WorkerConfiguration, RequestSenderError>) -> Void
    ) throws
}
