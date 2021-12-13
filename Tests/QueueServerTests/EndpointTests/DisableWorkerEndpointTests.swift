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

final class DisableWorkerEndpointTests: XCTestCase {
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerConfigurations = FixedWorkerConfigurations()
    lazy var workerId = WorkerId(value: "worker")
    lazy var endpoint = DisableWorkerEndpoint(
        workerAlivenessProvider: workerAlivenessProvider,
        workerConfigurations: workerConfigurations
    )
    
    func test___does_not_indicate_activity() {
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity. Asking queue to disable worker should not prolong its lifetime."
        )
    }
        
    func test___disabling_existing_worker() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        assertDoesNotThrow {
            let response = try endpoint.handle(payload: DisableWorkerPayload(workerId: workerId))
            XCTAssertEqual(response.workerId, workerId)
        }
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: workerId),
            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [], disabled: true, silent: false, workerUtilizationPermission: .allowedToUtilize)
        )
    }
    
    func test___disabling_non_existing_worker___throws() {
        assertThrows {
            try endpoint.handle(payload: DisableWorkerPayload(workerId: "random_id"))
        }
    }
    
    func test___disabling_already_disabled_worker___throws() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.disableWorker(workerId: workerId)
        
        assertThrows {
            try endpoint.handle(payload: DisableWorkerPayload(workerId: workerId))
        }
    }
}
