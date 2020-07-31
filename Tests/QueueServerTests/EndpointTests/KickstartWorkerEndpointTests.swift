import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import QueueModels
import QueueServer
import RESTMethods
import TestHelpers
import WorkerAlivenessModels
import WorkerAlivenessProvider
import XCTest

final class KickstartWorkerEndpointTests: XCTestCase {
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(knownWorkerIds: [workerId])
    lazy var workerConfigurations = WorkerConfigurations()
    lazy var workerId = WorkerId(value: "worker")
    lazy var onDemandWorkerStarter = FakeOnDemandWorkerStarter()
    lazy var endpoint = KickstartWorkerEndpoint(
        onDemandWorkerStarter: onDemandWorkerStarter,
        workerAlivenessProvider: workerAlivenessProvider,
        workerConfigurations: workerConfigurations
    )
    
    func test___does_not_indicate_activity() {
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity. Asking queue to kickstart worker should not prolong its lifetime."
        )
    }
    
    func test___kickstarting_existing_silent_worker() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.setWorkerIsSilent(workerId: workerId)

        assertDoesNotThrow {
            let response = try endpoint.handle(payload: KickstartWorkerPayload(workerId: workerId))
            XCTAssertEqual(response.workerId, workerId)
        }

        XCTAssertEqual(
            onDemandWorkerStarter.startedWorkerId,
            workerId
        )
    }
    
    func test___kickstarting_non_existing_worker___throws() {
        assertThrows {
            try endpoint.handle(payload: KickstartWorkerPayload(workerId: "random_id"))
        }
    }
    
    func test___disabling_already_disabled_worker___throws() {
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        assertThrows {
            try endpoint.handle(payload: KickstartWorkerPayload(workerId: workerId))
        }
    }
}
