import BalancingBucketQueue
import Foundation
import Models
import RESTMethods

public final class JobDeleteEndpoint: RESTEndpoint {
    private let jobManipulator: JobManipulator
    
    public init(jobManipulator: JobManipulator) {
        self.jobManipulator = jobManipulator
    }
    
    public func handle(decodedRequest: JobDeleteRequest) throws -> JobDeleteResponse {
        try jobManipulator.delete(jobId: decodedRequest.jobId)
        return JobDeleteResponse(jobId: decodedRequest.jobId)
    }
}
