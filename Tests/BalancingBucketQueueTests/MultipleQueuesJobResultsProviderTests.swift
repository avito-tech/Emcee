import BalancingBucketQueue
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesJobResultsProviderTests: XCTestCase {
    private lazy var container = MultipleQueuesContainer()
    private lazy var provider = MultipleQueuesJobResultsProvider(
        multipleQueuesContainer: container
    )
    
    func test___results_for_non_existing_queue___throws() {
        assertThrows {
            try provider.results(jobId: "job")
        }
    }
    
    func test___results_for_deleted_job() {
        let resultsCollector = ResultsCollector()
        resultsCollector.append(
            testingResult: TestingResultFixtures().addingResult(success: true).testingResult()
        )
        
        container.add(
            deletedJobQueues: [
                createJobQueue(
                    job: createJob(jobId: "jobId"),
                    resultsCollector: resultsCollector
                )
            ]
        )
        
        XCTAssertEqual(
            try provider.results(jobId: "jobId"),
            JobResults(jobId: "jobId", testingResults: resultsCollector.collectedResults)
        )
    }
    
    func test___results_for_running_job() {
        let resultsCollector = ResultsCollector()
        resultsCollector.append(
            testingResult: TestingResultFixtures().addingResult(success: true).testingResult()
        )
        
        container.add(
            runningJobQueue: createJobQueue(
                job: createJob(jobId: "jobId"),
                resultsCollector: resultsCollector
            )
        )
        
        XCTAssertEqual(
            try provider.results(jobId: "jobId"),
            JobResults(jobId: "jobId", testingResults: resultsCollector.collectedResults)
        )
    }
}
