import BalancingBucketQueue
import Foundation
import RESTInterfaces
import RESTMethods
import RESTServer

public final class JobStateEndpoint: RESTEndpoint {
    private let stateProvider: JobStateProvider
    public let path: RESTPath = JobStateRESTMethod()
    public let requestIndicatesActivity = false

    public init(stateProvider: JobStateProvider) {
        self.stateProvider = stateProvider
    }
    
    public func handle(payload: JobStatePayload) throws -> JobStateResponse {
        let jobState = try stateProvider.state(jobId: payload.jobId)
        return JobStateResponse(jobState: jobState)
    }
}
