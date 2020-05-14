import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import Models
import QueueServer
import RESTMethods
import TestHelpers
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class DisableWorkerEndpointTests: XCTestCase {
    lazy var workerAlivenessProvider = WorkerAlivenessProviderFixtures.alivenessTrackerWithAlwaysAliveResults()
    lazy var workerConfigurations = WorkerConfigurations()
    lazy var workerId = WorkerId(value: "worker")
    lazy var endpoint = DisableWorkerEndpoint(
        workerAlivenessProvider: workerAlivenessProvider,
        workerConfigurations: workerConfigurations
    )
        
    func test___disabling_existing_worker() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        assertDoesNotThrow {
            let response = try endpoint.handle(decodedPayload: DisableWorkerPayload(workerId: workerId))
            XCTAssertEqual(response.workerId, workerId)
        }
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: workerId),
            WorkerAliveness(status: .disabled, bucketIdsBeingProcessed: [])
        )
    }
    
    func test___disabling_non_existing_worker___throws() {
        assertThrows {
            _ = try endpoint.handle(decodedPayload: DisableWorkerPayload(workerId: "random_id"))
        }
    }
    
    func test___disabling_already_disabled_worker___throws() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.disableWorker(workerId: workerId)
        
        assertThrows {
            _ = try endpoint.handle(decodedPayload: DisableWorkerPayload(workerId: "random_id"))
        }
    }
}
