import Dispatch
import DistWorkerModels
import Models
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class WorkerRegistererImpl: WorkerRegisterer {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func registerWithServer(
        workerId: WorkerId,
        workerRestAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    ) {
        requestSender.sendRequestWithCallback(
            request: RegisterWorkerRequest(
                payload: RegisterWorkerPayload(
                    workerId: workerId,
                    workerRestAddress: workerRestAddress
                )
            ),
            callbackQueue: callbackQueue,
            callback: { (result: Either<RegisterWorkerResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    switch response {
                    case .workerRegisterSuccess(let workerConfiguration):
                        completion(Either.success(workerConfiguration))
                    }
                } catch {
                    completion(Either.error(error))
                }
            }
        )
    }
}
