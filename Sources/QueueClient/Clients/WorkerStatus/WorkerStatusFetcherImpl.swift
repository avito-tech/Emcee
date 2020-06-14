import Dispatch
import Foundation
import Models
import RESTMethods
import RequestSender
import WorkerAlivenessModels

public final class WorkerStatusFetcherImpl: WorkerStatusFetcher {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func fetch(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<[WorkerId: WorkerAliveness], Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            request: WorkerStatusRequest(payload: WorkerStatusPayload()),
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerStatusResponse, RequestSenderError>) in
            do {
                let response = try result.dematerialize()
                completion(.success(response.workerAliveness))
            } catch {
                completion(.error(error))
            }
        }
    }
}
