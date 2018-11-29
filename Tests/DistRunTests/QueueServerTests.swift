import DistRun
import DistWork
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class QueueServerTests: XCTestCase {
    let eventBus = EventBus()
    let workerConfigurations = WorkerConfigurations()
    let workerId = "workerId"
    
    func test__queue_waits_for_new_workers_and_fails_if_they_not_appear_in_time() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let server = QueueServer(
            eventBus: EventBus(),
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            numberOfRetries: 0,
            newWorkerRegistrationTimeAllowance: 0.0)
        XCTAssertThrowsError(try server.waitForQueueToFinish())
    }
    
    func test__queue_waits_for_depletion__when_worker_register_with_queue() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntry(className: "class", methodName: "test", caseId: nil)])
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let server = QueueServer(
            eventBus: EventBus(),
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            numberOfRetries: 0,
            newWorkerRegistrationTimeAllowance: .infinity,
            queueExhaustTimeAllowance: 0.0)
        server.add(buckets: [bucket])
        
        let port = try server.start()
        
        let client = SynchronousQueueClient(serverAddress: "localhost", serverPort: port, workerId: workerId)
        XCTAssertNoThrow(_ = try client.registerWithServer())
        
        XCTAssertThrowsError(try server.waitForQueueToFinish())
    }
    
    func test__queue_resturns_results_after_depletion() throws {
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        let testingResult = TestingResultFixtures()
            .with(testEntry: testEntry)
            .addingLostResult()
            .testingResult()
        
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        let server = QueueServer(
            eventBus: EventBus(),
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            numberOfRetries: 0,
            newWorkerRegistrationTimeAllowance: .infinity,
            queueExhaustTimeAllowance: 10.0)
        server.add(buckets: [bucket])
        
        let port = try server.start()
        
        let expectationForResults = expectation(description: "results became available")
        
        var actualResults = [TestingResult]()
        DispatchQueue.global().async {
            do {
                actualResults.append(contentsOf: try server.waitForQueueToFinish())
                expectationForResults.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        let client = SynchronousQueueClient(serverAddress: "localhost", serverPort: port, workerId: workerId)
        XCTAssertNoThrow(_ = try client.registerWithServer())
        let fetchResult = try client.fetchBucket(requestId: "request")
        XCTAssertEqual(fetchResult, SynchronousQueueClient.BucketFetchResult.bucket(bucket))
        XCTAssertNoThrow(try client.send(testingResult: testingResult, requestId: "request"))
        
        wait(for: [expectationForResults], timeout: 10)
        
        XCTAssertEqual([testingResult], actualResults)
    }
}

