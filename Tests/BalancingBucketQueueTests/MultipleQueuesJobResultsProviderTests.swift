import BalancingBucketQueue
import BucketQueueTestHelpers
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
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
            bucketResult: .testingResult(
                TestingResultFixtures().addingResult(success: true).testingResult()
            )
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
            JobResults(jobId: "jobId", bucketResults: resultsCollector.collectedResults)
        )
    }
    
    func test___results_for_running_job() {
        let resultsCollector = ResultsCollector()
        resultsCollector.append(
            bucketResult: .testingResult(
                TestingResultFixtures().addingResult(success: true).testingResult()
            )
        )
        
        container.add(
            runningJobQueue: createJobQueue(
                job: createJob(jobId: "jobId"),
                resultsCollector: resultsCollector
            )
        )
        
        XCTAssertEqual(
            try provider.results(jobId: "jobId"),
            JobResults(jobId: "jobId", bucketResults: resultsCollector.collectedResults)
        )
    }
}
