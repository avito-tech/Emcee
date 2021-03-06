import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

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
                completion(
                    result.mapResult { $0.workerId }
                )
            }
        )
    }
}
