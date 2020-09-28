import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class JobResultsFetcherImpl: JobResultsFetcher {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func fetch(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<JobResults, Error>) -> ()
    ) {
        let request = JobResultRequest(
            payload: JobResultsPayload(
                jobId: jobId
            )
        )
        
        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue,
            callback: { (response: Either<JobResultsResponse, RequestSenderError>) in
                completion(
                    response.mapResult { $0.jobResults }
                )
            }
        )
    }
}
