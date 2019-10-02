import Dispatch
import RequestSender
import Models
import RESTMethods

public final class WorkerRegistererImpl: WorkerRegisterer {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func registerWithServer(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    ) {
        requestSender.sendRequestWithCallback(
            pathWithSlash: RESTMethod.registerWorker.withPrependingSlash,
            payload: RegisterWorkerRequest(workerId: workerId),
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
