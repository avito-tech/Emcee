import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class WorkerKickstarterImpl: WorkerKickstarter {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func kickstart(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            request: KickstartWorkerRequest(payload: KickstartWorkerPayload(workerId: workerId)),
            callbackQueue: callbackQueue,
            callback: { (result: Either<KickstartWorkerResponse, RequestSenderError>) in
                do {
                    completion(.success(try result.dematerialize().workerId))
                } catch {
                    completion(.error(error))
                }
            }
        )
    }
}
