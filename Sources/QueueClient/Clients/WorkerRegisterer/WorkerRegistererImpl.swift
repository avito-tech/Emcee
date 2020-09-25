import Dispatch
import DistWorkerModels
import QueueModels
import RESTMethods
import RequestSender
import SocketModels
import Types
import WorkerCapabilitiesModels

public final class WorkerRegistererImpl: WorkerRegisterer {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func registerWithServer(
        workerId: WorkerId,
        workerCapabilities: Set<WorkerCapability>,
        workerRestAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerConfiguration, Error>) -> Void
    ) {
        requestSender.sendRequestWithCallback(
            request: RegisterWorkerRequest(
                payload: RegisterWorkerPayload(
                    workerId: workerId,
                    workerCapabilities: workerCapabilities,
                    workerRestAddress: workerRestAddress
                )
            ),
            callbackQueue: callbackQueue,
            callback: { (result: Either<RegisterWorkerResponse, RequestSenderError>) in
                completion(
                    result.mapResult {
                        switch $0 {
                        case .workerRegisterSuccess(let workerConfiguration):
                            return workerConfiguration
                        }
                    }
                )
            }
        )
    }
}
