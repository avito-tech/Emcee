import Deployer
import DeployerTestHelpers
import Models
import TestHelpers
import QueueCommunication
import QueueCommunicationTestHelpers
import XCTest

class WorkerUtilizationStatusPollerTests: XCTestCase {
    private let communicationService = FakeQueueCommunicationService()
    
    func test___poller_uses_default_deployments___if_no_data_was_fetched() {
        let deployments = [
            DeploymentDestinationFixtures().with(host: "workerId1").buildDeploymentDestination(),
            DeploymentDestinationFixtures().with(host: "workerId2").buildDeploymentDestination()
        ]
        
        let poller = buildPoller(deployments: deployments)
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    func test___poller_uses_fetched_worker_ids___if_workers_data_was_fetched() {
        let deployments = [
            DeploymentDestinationFixtures().with(host: "workerId1").buildDeploymentDestination(),
            DeploymentDestinationFixtures().with(host: "workerId2").buildDeploymentDestination()
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId3")]))
            expectation.fulfill()
        }
        let poller = buildPoller(deployments: deployments)
        
        poller.startPolling()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .allowedToUtilize)
    }
    
    func test___poller_uses_default_deployments___fetch_error_occured() {
        let deployments = [
            DeploymentDestinationFixtures().with(host: "workerId1").buildDeploymentDestination(),
            DeploymentDestinationFixtures().with(host: "workerId2").buildDeploymentDestination()
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.error(ErrorForTestingPurposes()))
            expectation.fulfill()
        }
        let poller = buildPoller(deployments: deployments)
        
        poller.startPolling()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    private func buildPoller(deployments: [DeploymentDestination]) -> DefaultWorkerUtilizationStatusPoller {
        DefaultWorkerUtilizationStatusPoller(
            defaultDeployments: deployments,
            communicationService: communicationService
        )
    }
}
