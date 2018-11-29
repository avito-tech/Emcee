import DistRun
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    let eventBus = EventBus()
    let resultsCollector = ResultsCollector()
    let testingResult = TestingResultFixtures()
        .with(testEntry: TestEntry(className: "class", methodName: "method", caseId: nil))
        .addingLostResult()
        .testingResult()

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        
        let registrar = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: eventBus,
            resultsCollector: resultsCollector,
            workerAlivenessTracker: WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults())
        
        let request = BucketResultRequest(workerId: "worker", requestId: "request", testingResult: testingResult)
        XCTAssertNoThrow(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(resultsCollector.collectedResults, [testingResult])
    }
    
    func test__results_collector_stays_unmodified_and_worker_is_blocked__if_bucket_queue_does_not_accept_results() {
        let alivenessTracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        alivenessTracker.didRegisterWorker(workerId: "worker")
        let bucketQueue = FakeBucketQueue(throwsOnAccept: true)
        
        let registrar = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: eventBus,
            resultsCollector: resultsCollector,
            workerAlivenessTracker: alivenessTracker)
        
        let request = BucketResultRequest(workerId: "worker", requestId: "request", testingResult: testingResult)
        XCTAssertThrowsError(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(resultsCollector.collectedResults, [])
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: "worker"), .blocked)
    }
}

