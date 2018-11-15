import DistRun
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    let eventBus = EventBus()
    let resultsCollector = ResultsCollector()
    let testingResult = TestingResultFixtures.createTestingResult(
        unfilteredResults: [
            TestEntryResult.lost(testEntry: TestEntry(className: "class", methodName: "method", caseId: nil))])

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        
        let registrar = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: eventBus,
            resultsCollector: resultsCollector)
        
        let request = BucketResultRequest(workerId: "worker", requestId: "request", testingResult: testingResult)
        XCTAssertNoThrow(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(resultsCollector.collectedResults, [testingResult])
    }
    
    func test__results_collector_stays_unmodified__if_bucket_queue_does_not_accept_results() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: true)
        
        let registrar = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: eventBus,
            resultsCollector: resultsCollector)
        
        let request = BucketResultRequest(workerId: "worker", requestId: "request", testingResult: testingResult)
        XCTAssertThrowsError(try registrar.handle(decodedRequest: request))
        
        XCTAssertEqual(resultsCollector.collectedResults, [])
    }
}

