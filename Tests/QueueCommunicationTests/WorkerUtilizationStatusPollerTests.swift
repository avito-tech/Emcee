import Graphite
import Metrics
import MetricsExtensions
import MetricsTestHelpers
import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import QueueServerPortProviderTestHelpers
import TestHelpers
import XCTest

class WorkerUtilizationStatusPollerTests: XCTestCase {
    private let communicationService = FakeQueueCommunicationService()
    private lazy var portProvider = FakeQueueServerPortProvider(port: 42)
    
    func test___poller_uses_default_deployments___if_no_data_was_fetched() {
        let workerIds: Set<WorkerId> = [
            "workerId1",
            "workerId2",
        ]
        
        let poller = buildPoller(workerIds: workerIds)
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    func test___poller_uses_fetched_worker_ids___if_workers_data_was_fetched() {
        let workerIds: Set<WorkerId> = [
            "workerId1",
            "workerId2",
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId3")]))
            expectation.fulfill()
        }
        let poller = buildPoller(workerIds: workerIds)
        
        poller.startUpdating()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .allowedToUtilize)
    }
    
    func test___poller_uses_default_deployments___fetch_error_occured() {
        let workerIds: Set<WorkerId> = [
            "workerId1",
            "workerId2",
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.error(ErrorForTestingPurposes()))
            expectation.fulfill()
        }
        let poller = buildPoller(workerIds: workerIds)
        
        poller.startUpdating()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    func test___poller_uses_default_worker_ids___if_workers_data_was_fetched_and_reset_was_called() {
        let workerIds: Set<WorkerId> = [
            "workerId1",
            "workerId2",
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId3")]))
            expectation.fulfill()
        }
        let poller = buildPoller(workerIds: workerIds)
        
        poller.startUpdating()
        wait(for: [expectation], timeout: 5)
        poller.stopUpdatingAndRestoreDefaultConfig()
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .allowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .notAllowedToUtilize)
    }
    
    func test___poller_starts_again___if_reset_was_called() {
        let workerIds: Set<WorkerId> = [
            "workerId1",
            "workerId2",
        ]
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId3")]))
            expectation.fulfill()
        }
        let poller = buildPoller(workerIds: workerIds)
        
        poller.stopUpdatingAndRestoreDefaultConfig()
        poller.startUpdating()
        wait(for: [expectation], timeout: 5)
        
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId1"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId2"), .notAllowedToUtilize)
        XCTAssertEqual(poller.utilizationPermissionForWorker(workerId: "workerId3"), .allowedToUtilize)
    }
    
    func test___poller_log_metric() {
        let expectedMetric1 = NumberOfWorkersToUtilizeMetric(emceeVersion: "emceeVersion", queueHost: "queueHost", workersCount: 0)
        let metricHandler = FakeMetricHandler<GraphiteMetric>()
        let metricQueue = DispatchQueue(label: "test")
        let expectation = self.expectation(description: "workersToUtilize was called")
        communicationService.completionHandler = { completion in
            completion(.success([WorkerId(value: "workerId")]))
            expectation.fulfill()
        }
        let expectedMetric2 = NumberOfWorkersToUtilizeMetric(emceeVersion: "emceeVersion", queueHost: "queueHost", workersCount: 1)
        let poller = buildPoller(
            workerIds: [],
            globalMetricRecorder: GlobalMetricRecorderImpl(
                graphiteHandler: metricHandler,
                statsdHandler: NoOpMetricHandler(),
                queue: metricQueue
            )
        )
        let expectedMetrics = Set([expectedMetric1, expectedMetric2])

        poller.startUpdating()

        wait(for: [expectation], timeout: 5)
        metricQueue.sync { }
        
        for expectedMetric in expectedMetrics {
            let contains = metricHandler.metrics.contains { metric -> Bool in
                expectedMetric.testCompare(metric)
            }
            if contains == false {
                XCTFail("No metric \(expectedMetrics) found")
            }
        }    
    }

    private func buildPoller(
        workerIds: Set<WorkerId>,
        globalMetricRecorder: GlobalMetricRecorder = GlobalMetricRecorderImpl()
    ) -> AutoupdatingWorkerPermissionProvider {
        AutoupdatingWorkerPermissionProviderImpl(
            communicationService: communicationService,
            initialWorkerIds: workerIds,
            emceeVersion: "emceeVersion",
            logger: .noOp,
            globalMetricRecorder: globalMetricRecorder,
            queueHost: "queueHost",
            queueServerPortProvider: portProvider
        )
    }
}
