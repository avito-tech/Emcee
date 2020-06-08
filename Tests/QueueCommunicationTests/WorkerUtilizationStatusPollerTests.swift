import Deployer
import DeployerTestHelpers
import Metrics
import MetricsTestHelpers
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
    
    func test___poller_uses_default_worker_ids___if_workers_data_was_fetched_and_reset_was_called() {
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
        poller.stopPollingAndRestoreDefaultConfig()
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    func test___poller_starts_again___if_reset_was_called() {
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
        
        poller.stopPollingAndRestoreDefaultConfig()
        poller.startPolling()
        wait(for: [expectation], timeout: 5)
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .allowedToUtilize)
    }
    
    func test___poller_log_metric() {
        let expectedMetric1 = NumberOfWorkersToUtilizeMetric(emceeVersion: "emceeVersion", queueHost: "queueHost", workersCount: 0)
        let metricHandler = FakeMetricHandler()
        GlobalMetricConfig.metricHandler = metricHandler
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId")]))
            expectation.fulfill()
        }
        let expectedMetric2 = NumberOfWorkersToUtilizeMetric(emceeVersion: "emceeVersion", queueHost: "queueHost", workersCount: 1)
        let poller = buildPoller(deployments: [])
        let expectedMetrics = Set([expectedMetric1, expectedMetric2])

        poller.startPolling()

        wait(for: [expectation], timeout: 5)

        for expectedMetric in expectedMetrics {
            let contains = metricHandler.metrics.contains { metric -> Bool in
                expectedMetric.testCompare(metric)
            }
            if contains == false {
                XCTFail("No metric \(expectedMetrics) found")
            }
        }    
    }

    private func buildPoller(deployments: [DeploymentDestination]) -> DefaultWorkerUtilizationStatusPoller {
        DefaultWorkerUtilizationStatusPoller(
            emceeVersion: "emceeVersion",
            queueHost: "queueHost",
            defaultDeployments: deployments,
            communicationService: communicationService
        )
    }
}
