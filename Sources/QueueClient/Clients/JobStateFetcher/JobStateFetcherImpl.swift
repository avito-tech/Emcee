import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class JobStateFetcherImpl: JobStateFetcher {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func fetch(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping ((Either<JobState, Error>) -> ())
    ) {
        let request = JobStateRequest(
            payload: JobStatePayload(
                jobId: jobId
            )
        )
        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue
        ) { (result: Either<JobStateResponse, RequestSenderError>) in
            completion(result.mapResult { $0.jobState })
        }
    }
}
