import BalancingBucketQueue
import Foundation
import RESTInterfaces
import RESTMethods
import RESTServer

public final class JobDeleteEndpoint: RESTEndpoint {
    private let jobManipulator: JobManipulator
    public let path: RESTPath = JobDeleteRESTMethod()
    public let requestIndicatesActivity = true
    
    public init(jobManipulator: JobManipulator) {
        self.jobManipulator = jobManipulator
    }
    
    public func handle(payload: JobDeletePayload) throws -> JobDeleteResponse {
        try jobManipulator.delete(jobId: payload.jobId)
        return JobDeleteResponse(jobId: payload.jobId)
    }
}
