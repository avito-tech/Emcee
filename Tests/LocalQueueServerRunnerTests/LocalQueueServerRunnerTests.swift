import AutomaticTermination
import AutomaticTerminationTestHelpers
import LocalQueueServerRunner
import ProcessControllerTestHelpers
import QueueCommunicationTestHelpers
import QueueModels
import QueueServer
import QueueServerTestHelpers
import RemotePortDeterminer
import RemotePortDeterminerTestHelpers
import ScheduleStrategy
import TemporaryStuff
import TestHelpers
import UniqueIdentifierGenerator
import XCTest

final class LocalQueueServerRunnerTests: XCTestCase {
    
    private let automaticTerminationController = AutomaticTerminationControllerFixture(isTerminationAllowed: false)
    private let queueServer = QueueServerFixture()
    private let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
        pollInterval: 0.1,
        queueServerTerminationPolicy: AutomaticTerminationPolicy.stayAlive
    )
    private let remotePortDeterminer = RemotePortDeterminerFixture(result: [:])
    private let workerUtilizationStatusPoller = FakeWorkerUtilizationStatusPoller()
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var runner = LocalQueueServerRunner(
        automaticTerminationController: automaticTerminationController,
        newWorkerRegistrationTimeAllowance: 60.0,
        pollPeriod: 0.1,
        processControllerProvider: FakeProcessControllerProvider(tempFolder: tempFolder),
        queueServer: queueServer,
        queueServerTerminationPolicy: AutomaticTerminationPolicy.stayAlive,
        queueServerTerminationWaiter: queueServerTerminationWaiter,
        remotePortDeterminer: remotePortDeterminer,
        temporaryFolder: tempFolder,
        uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
        workerDestinations: [],
        workerUtilizationStatusPoller: workerUtilizationStatusPoller
    )
    
    let runnerQueue = DispatchQueue(label: "runner queue")
    let impactQueue = DispatchQueue(label: "impact queue")
    
    func test___queue_server_runner_should_wait___while_automatic_termination_is_not_allowed() throws {
        let expectation = self.expectation(description: "runner should wait while automatic termination is not allowed and it has alive workers")
        expectation.isInverted = true
        
        queueServer.isDepleted = true
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_should_wait___while_queue_is_not_depleted() throws {
        let expectation = self.expectation(description: "runner should wait while it has alive workers and queue is not depleted")
        expectation.isInverted = true
        
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = false
        queueServer.ongoingJobIds = [JobId(value: "jobid")]
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_should_wait___while_queue_has_jobs() throws {
        let expectation = self.expectation(description: "runner should wait while it has alive workers and queue has jobs")
        expectation.isInverted = true
        
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = true
        queueServer.ongoingJobIds = [JobId(value: "jobid")]
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test___queue_server_runner_stops___after_all_workers_have_died() throws {
        let expectation = self.expectation(description: "runner should stop when queue has no alive workers")
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.hasAnyAliveWorker = false
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination() throws {
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows")
        queueServer.isDepleted = true
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.automaticTerminationController.isTerminationAllowed = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination_is_allowed_and_queue_depletes() throws {
        automaticTerminationController.isTerminationAllowed = true
        
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows and after queue has been depleted")
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.isDepleted = true
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_stops___after_automatic_termination_is_allowed_and_queue_has_no_jobs_left() throws {
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = true
        queueServer.ongoingJobIds.insert(JobId(value: UUID().uuidString))
        
        let expectation = self.expectation(description: "runner should stop when automatic termination controller allows and after queue has no jobs left")
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        impactQueue.asyncAfter(deadline: .now() + 0.1) {
            self.queueServer.ongoingJobIds.removeAll()
        }
        
        wait(for: [expectation], timeout: 60.0)
    }

    func test___queue_server_runner_should_wait___while_workers_are_being_started_and_registered() throws {
        let expectation = self.expectation(description: "runner should wait while workers are being registered")

        queueServer.hasAnyAliveWorker = false
        automaticTerminationController.isTerminationAllowed = true
        queueServer.isDepleted = true
        queueServer.ongoingJobIds = []

        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }

        impactQueue.async {
            self.queueServer.hasAnyAliveWorker = true
        }

        wait(for: [expectation], timeout: 60.0)
    }
    
    func test___queue_server_runner_fails_to_start___if_queue_with_same_version_is_already_running() throws {
        let emceeVersion: Version = "emceeVersion"
        remotePortDeterminer.set(port: 1234, version: emceeVersion)
        
        XCTAssertThrowsError(try runner.start(emceeVersion: emceeVersion))
    }
    
    func test___start_polling_called___upon_runner_start() throws {
        let expectation = self.expectation(description: "runner started")
        expectation.isInverted = true
        
        queueServer.isDepleted = true
        
        runnerQueue.async {
            _ = try? self.runner.start(emceeVersion: "emceeVersion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(self.workerUtilizationStatusPoller.startPollingCalled)
    }
}
