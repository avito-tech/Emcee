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
    
    public func fetchQueueServerVersion(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Version, Error>) -> Void
    ) {
        requestSender.sendRequestWithCallback(
            request: QueueVersionRequest(),
            callbackQueue: callbackQueue,
            callback: { (result: Either<QueueVersionResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    switch response {
                    case .queueVersion(let version):
                        completion(Either.success(version))
                    }
                } catch {
                    completion(Either.error(error))
                }
            }
        )
    }
}
