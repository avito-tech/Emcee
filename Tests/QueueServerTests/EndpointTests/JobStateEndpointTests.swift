import BalancingBucketQueue
import Foundation
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import XCTest

final class JobStateEndpointTests: XCTestCase, JobStateProvider {
    private struct Throwable: Error {}
    private let jobId: JobId = "jobid"
    private lazy var jobState = JobState(
        jobId: jobId,
        queueState: QueueState.running(
            RunningQueueStateFixtures.runningQueueState()
        )
    )
    
    var ongoingJobIds: Set<JobId> {
        return [jobId]
    }
    
    var ongoingJobGroupIds: Set<JobGroupId> { return [] }
    
    func state(jobId: JobId) throws -> JobState {
        guard jobId == self.jobId else { throw Throwable() }
        return jobState
    }
    
    var allJobStates: [JobState] {
        return [jobState]
    }
    
    func test___does_not_indicate_activity() {
        let endpoint = JobStateEndpoint(stateProvider: self)
        
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity because simply checks if job is finished; no state or results manipulation involved. Checks are happening very often."
        )
    }
    
    func test___requesting_job_state_for_existing_job() throws {
        let endpoint = JobStateEndpoint(stateProvider: self)
        let response = try endpoint.handle(payload: JobStatePayload(jobId: jobId))
        XCTAssertEqual(response.jobState, jobState)
    }
    
    func test___request_state_for_non_existing_job() {
        let endpoint = JobStateEndpoint(stateProvider: self)
        XCTAssertThrowsError(try endpoint.handle(payload: JobStatePayload(jobId: "invalid_job")))
    }
}

