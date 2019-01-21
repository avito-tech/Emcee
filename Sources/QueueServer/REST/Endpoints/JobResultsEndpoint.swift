import BalancingBucketQueue
import Extensions
import Foundation
import Models
import RESTMethods

public final class JobResultsEndpoint: RESTEndpoint {
    private let jobResultsProvider: JobResultsProvider

    public init(jobResultsProvider: JobResultsProvider) {
        self.jobResultsProvider = jobResultsProvider
    }
    
    public func handle(decodedRequest: JobResultsRequest) throws -> JobResultsResponse {
        let jobResults = try jobResultsProvider.results(jobId: decodedRequest.jobId)
        return JobResultsResponse(jobResults: jobResults)
    }
}
