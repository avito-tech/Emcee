import BalancingBucketQueue
import Extensions
import Foundation
import Models
import RESTInterfaces
import RESTMethods
import RESTServer

public final class JobResultsEndpoint: RESTEndpoint {
    private let jobResultsProvider: JobResultsProvider
    public let path: RESTPath = RESTMethod.jobResults
    public let requestIndicatesActivity = true

    public init(jobResultsProvider: JobResultsProvider) {
        self.jobResultsProvider = jobResultsProvider
    }
    
    public func handle(payload: JobResultsRequest) throws -> JobResultsResponse {
        let jobResults = try jobResultsProvider.results(jobId: payload.jobId)
        return JobResultsResponse(jobResults: jobResults)
    }
}
