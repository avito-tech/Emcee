import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

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
                completion(
                    result.mapResult { $0.workerId }
                )
            }
        )
    }
}
