import BalancingBucketQueue
import Extensions
import Foundation
import Models
import RESTMethods
import RESTServer

public final class JobStateEndpoint: RESTEndpoint {
    private let stateProvider: JobStateProvider

    public init(stateProvider: JobStateProvider) {
        self.stateProvider = stateProvider
    }
    
    public func handle(decodedPayload: JobStateRequest) throws -> JobStateResponse {
        let jobState = try stateProvider.state(jobId: decodedPayload.jobId)
        return JobStateResponse(jobState: jobState)
    }
}
