import Dispatch
import Foundation
import Models
import RESTMethods
import RequestSender

public final class WorkerDisablerImpl: WorkerDisabler {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func disableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            request: DisableWorkerRequest(payload: DisableWorkerPayload(workerId: workerId)),
            callbackQueue: callbackQueue,
            callback: { (result: Either<WorkerDisabledResponse, RequestSenderError>) in
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
