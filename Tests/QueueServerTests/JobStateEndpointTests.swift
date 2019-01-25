import BalancingBucketQueue
import Foundation
import Models
import QueueServer
import RESTMethods
import XCTest

final class JobStateEndpointTests: XCTestCase, JobStateProvider {
    private struct Throwable: Error {}
    private let jobId: JobId = "jobid"
    private lazy var jobState = JobState(
        jobId: jobId,
        queueState: QueueState(
            enqueuedBucketCount: 24,
            dequeuedBucketCount: 42
        )
    )
    
    func state(jobId: JobId) throws -> JobState {
        guard jobId == self.jobId else { throw Throwable() }
        return jobState
    }
    
    func test___requesting_job_state_for_existing_job() throws {
        let endpoint = JobStateEndpoint(stateProvider: self)
        let response = try endpoint.handle(decodedRequest: JobStateRequest(jobId: jobId))
        XCTAssertEqual(response.jobState, jobState)
    }
    
    func test___request_state_for_non_existing_job() {
        let endpoint = JobStateEndpoint(stateProvider: self)
        XCTAssertThrowsError(try endpoint.handle(decodedRequest: JobStateRequest(jobId: "invalid_job")))
    }
}
