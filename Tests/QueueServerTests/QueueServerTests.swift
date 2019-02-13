import AutomaticTermination
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import PortDeterminer
import QueueClient
import QueueServer
import ScheduleStrategy
import VersionTestHelpers
import XCTest

final class QueueServerTests: XCTestCase {
    let eventBus = EventBus()
    let workerConfigurations = WorkerConfigurations()
    let workerId = "workerId"
    let jobId: JobId = "jobId"
    lazy var prioritizedJob = PrioritizedJob(jobId: jobId, priority: .medium)
    let automaticTerminationController = AutomaticTerminationControllerFactory(
        automaticTerminationPolicy: .stayAlive
    ).createAutomaticTerminationController()
    let localPortDeterminer = LocalPortDeterminer(portRange: Ports.allPrivatePorts)
    let bucketSplitter = ScheduleStrategyType.individual.bucketSplitter()
    let bucketSplitInfo = BucketSplitInfoFixtures.bucketSplitInfoFixture()
    let queueVersionProvider = VersionProviderFixture().buildVersionProvider()
    
    func test__queue_waits_for_new_workers_and_fails_if_they_not_appear_in_time() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let server = QueueServer(
            automaticTerminationController: automaticTerminationController,
            eventBus: eventBus,
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            newWorkerRegistrationTimeAllowance: 0.0,
            checkAgainTimeInterval: .infinity, 
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersTerminateWhenQueueIsDepleted,
            bucketSplitter: bucketSplitter,
            bucketSplitInfo: bucketSplitInfo,
            queueServerLock: NeverLockableQueueServerLock(),
            queueVersionProvider: queueVersionProvider
        )
        XCTAssertThrowsError(try server.waitForJobToFinish(jobId: jobId))
    }
    
    func test__queue_waits_for_depletion__when_worker_register_with_queue() throws {
        let testEntryConfiguration = TestEntryConfigurationFixtures()
            .add(testEntry: TestEntry(className: "class", methodName: "test", caseId: nil))
            .testEntryConfigurations()
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let server = QueueServer(
            automaticTerminationController: automaticTerminationController,
            eventBus: EventBus(),
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            newWorkerRegistrationTimeAllowance: .infinity,
            queueExhaustTimeAllowance: 0.0,
            checkAgainTimeInterval: .infinity,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersTerminateWhenQueueIsDepleted,
            bucketSplitter: bucketSplitter,
            bucketSplitInfo: bucketSplitInfo,
            queueServerLock: NeverLockableQueueServerLock(),
            queueVersionProvider: queueVersionProvider
        )
        server.schedule(testEntryConfigurations: testEntryConfiguration, prioritizedJob: prioritizedJob)
        
        let client = synchronousQueueClient(port: try server.start())
        
        XCTAssertNoThrow(_ = try client.registerWithServer(workerId: workerId))
        XCTAssertThrowsError(try server.waitForJobToFinish(jobId: jobId))
    }
    
    func test__queue_returns_results_after_depletion() throws {
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        let testEntryConfigurations = TestEntryConfigurationFixtures()
            .add(testEntry: testEntry)
            .testEntryConfigurations()
        let testingResult = TestingResultFixtures()
            .with(testEntry: testEntry)
            .addingLostResult()
            .testingResult()
        
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        let server = QueueServer(
            automaticTerminationController: automaticTerminationController,
            eventBus: EventBus(),
            workerConfigurations: workerConfigurations,
            reportAliveInterval: .infinity,
            newWorkerRegistrationTimeAllowance: .infinity,
            queueExhaustTimeAllowance: 10.0,
            checkAgainTimeInterval: .infinity,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersTerminateWhenQueueIsDepleted,
            bucketSplitter: bucketSplitter,
            bucketSplitInfo: bucketSplitInfo,
            queueServerLock: NeverLockableQueueServerLock(),
            queueVersionProvider: queueVersionProvider
        )
        server.schedule(testEntryConfigurations: testEntryConfigurations, prioritizedJob: prioritizedJob)
        
        let expectationForResults = expectation(description: "results became available")
        
        var actualResults = [JobResults]()
        DispatchQueue.global().async {
            do {
                actualResults.append(try server.waitForJobToFinish(jobId: self.jobId))
                expectationForResults.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        let client = synchronousQueueClient(port: try server.start())
        XCTAssertNoThrow(_ = try client.registerWithServer(workerId: workerId))
        let fetchResult = try client.fetchBucket(requestId: "request", workerId: workerId)
        XCTAssertEqual(fetchResult, SynchronousQueueClient.BucketFetchResult.bucket(bucket))
        XCTAssertNoThrow(try client.send(testingResult: testingResult, requestId: "request", workerId: workerId))
        
        wait(for: [expectationForResults], timeout: 10)
        
        XCTAssertEqual(
            [JobResults(jobId: jobId, testingResults: [testingResult])],
            actualResults
        )
    }
    
    private func synchronousQueueClient(port: Int) -> SynchronousQueueClient {
        return SynchronousQueueClient(queueServerAddress: SocketAddress(host: "localhost", port: port))
    }
}

