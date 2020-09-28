import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class JobDeleterImpl: JobDeleter {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func delete(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<(), Error>) -> ()
    ) {
        let request = JobDeleteRequest(
            payload: JobDeletePayload(
                jobId: jobId
            )
        )
        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue
        ) { (result: Either<JobDeleteResponse, RequestSenderError>) in
            completion(result.mapResult { _ in () })
        }
    }
}
