import BalancingBucketQueue
import Foundation
import RESTInterfaces
import RESTMethods
import RESTServer

public final class JobResultsEndpoint: RESTEndpoint {
    private let jobResultsProvider: JobResultsProvider
    public let path: RESTPath = JobResultsRESTMethod()
    public let requestIndicatesActivity = true

    public init(jobResultsProvider: JobResultsProvider) {
        self.jobResultsProvider = jobResultsProvider
    }
    
    public func handle(payload: JobResultsPayload) throws -> JobResultsResponse {
        let jobResults = try jobResultsProvider.results(jobId: payload.jobId)
        return JobResultsResponse(jobResults: jobResults)
    }
}
