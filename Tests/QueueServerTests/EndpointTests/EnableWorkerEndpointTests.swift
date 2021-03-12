import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueServer
import RESTMethods
import TestHelpers
import WorkerAlivenessModels
import WorkerAlivenessProvider
import XCTest

final class EnableWorkerEndpointTests: XCTestCase {
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId],
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerConfigurations = WorkerConfigurations()
    lazy var workerId = WorkerId(value: "worker")
    lazy var endpoint = EnableWorkerEndpoint(
        workerAlivenessProvider: workerAlivenessProvider,
        workerConfigurations: workerConfigurations
    )
    
    func test___does_not_indicate_activity() {
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity. Asking queue to enable worker should not prolong its lifetime."
        )
    }
        
    func test___enabling_existing_worker() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.disableWorker(workerId: workerId)
        
        assertDoesNotThrow {
            let response = try endpoint.handle(payload: EnableWorkerPayload(workerId: workerId))
            XCTAssertEqual(response.workerId, workerId)
        }
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: workerId),
            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [], disabled: false, silent: false, workerUtilizationPermission: .allowedToUtilize)
        )
    }
    
    func test___enabling_non_existing_worker___throws() {
        assertThrows {
            try endpoint.handle(payload: EnableWorkerPayload(workerId: "random_id"))
        }
    }
    
    func test___enabling_already_enabled_worker___throws() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        assertThrows {
            try endpoint.handle(payload: EnableWorkerPayload(workerId: workerId))
        }
    }
}
