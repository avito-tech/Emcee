import Dispatch
import Foundation
import Models
import RESTMethods
import RequestSender

public final class WorkerEnablerImpl: WorkerEnabler {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func enableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            request: EnableWorkerRequest(payload: EnableWorkerPayload(workerId: workerId)),
            callbackQueue: callbackQueue,
            callback: { (result: Either<WorkerEnabledResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    completion(.success(response.workerId))
                } catch {
                    completion(.error(error))
                }
            }
        )
    }
}
