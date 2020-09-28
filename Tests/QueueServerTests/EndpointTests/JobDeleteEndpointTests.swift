import BalancingBucketQueue
import Foundation
import QueueModels
import QueueServer
import RESTMethods
import XCTest

final class JobDeleteEndpointTests: XCTestCase, JobManipulator {
    private struct Throwable: Error {}
    private let jobId: JobId = "jobid"
    private var shouldThrow = false
    
    func delete(jobId: JobId) throws {
        if shouldThrow {
            throw Throwable()
        }
    }
    
    func test___indicates_activity() {
        let endpoint = JobDeleteEndpoint(jobManipulator: self)
        
        XCTAssertTrue(
            endpoint.requestIndicatesActivity,
            "This endpoint should indicate activity because it modifies the queue state"
        )
    }

    func test___successful_deletion_of_job() throws {
        shouldThrow = false
        
        let endpoint = JobDeleteEndpoint(jobManipulator: self)
        let response = try endpoint.handle(payload: JobDeletePayload(jobId: jobId))
        XCTAssertEqual(response.jobId, jobId)
    }
    
    func test___errors_are_propagated() {
        shouldThrow = true
        
        let endpoint = JobDeleteEndpoint(jobManipulator: self)
        XCTAssertThrowsError(_ = try endpoint.handle(payload: JobDeletePayload(jobId: jobId)))
    }
}

