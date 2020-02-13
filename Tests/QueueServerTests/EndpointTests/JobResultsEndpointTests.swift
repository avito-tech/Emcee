import BalancingBucketQueue
import Foundation
import Models
import QueueModels
import ModelsTestHelpers
import QueueServer
import RESTMethods
import XCTest

final class JobResultsEndpointTests: XCTestCase, JobResultsProvider {
    private struct Throwable: Error {}
    private let jobId: JobId = "jobid"
    private lazy var jobResults = JobResults(
        jobId: jobId,
        testingResults: [TestingResult(
            bucketId: "bucketid",
            testDestination: TestDestinationFixtures.testDestination,
            unfilteredResults: [TestEntryResult.lost(testEntry: TestEntryFixtures.testEntry())]
            )
        ]
    )
    
    func results(jobId: JobId) throws -> JobResults {
        guard jobId == self.jobId else { throw Throwable() }
        return jobResults
    }
    
    func test___requesting_job_results_for_existing_job() throws {
        let endpoint = JobResultsEndpoint(jobResultsProvider: self)
        let response = try endpoint.handle(decodedPayload: JobResultsRequest(jobId: jobId))
        XCTAssertEqual(response.jobResults, jobResults)
    }
    
    func test___request_state_for_non_existing_job() {
        let endpoint = JobResultsEndpoint(jobResultsProvider: self)
        XCTAssertThrowsError(try endpoint.handle(decodedPayload: JobResultsRequest(jobId: "invalid job id")))
    }
}

