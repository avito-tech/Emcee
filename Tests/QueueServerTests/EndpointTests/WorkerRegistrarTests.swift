import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import TestHelpers
import WorkerAlivenessProvider
import XCTest

final class WorkerRegistrarTests: XCTestCase {
    lazy var alivenessTracker = WorkerAlivenessProviderImpl(knownWorkerIds: [workerId])
    let workerConfigurations = WorkerConfigurations()
    let workerId: WorkerId = "worker_id"
    
    override func setUp() {
        super.setUp()
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    private func createRegistrar() -> WorkerRegistrar {
        return WorkerRegistrar(
            workerAlivenessProvider: alivenessTracker,
            workerConfigurations: workerConfigurations,
            workerDetailsHolder: WorkerDetailsHolderImpl()
        )
    }
    
    func test_registration_for_known_worker() throws {
        let registrar = createRegistrar()
        XCTAssertFalse(alivenessTracker.alivenessForWorker(workerId: workerId).registered)
        
        XCTAssertEqual(
            try registrar.handle(
                payload: RegisterWorkerPayload(
                    workerId: workerId,
                    workerRestAddress: SocketAddress(host: "host", port: 0)
                )
            ),
            .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
        XCTAssertTrue(alivenessTracker.alivenessForWorker(workerId: workerId).registered)
        XCTAssertTrue(alivenessTracker.alivenessForWorker(workerId: workerId).alive)
    }
    
    func test_successful_registration() throws {
        let registrar = createRegistrar()
        
        let response = try registrar.handle(
            payload: RegisterWorkerPayload(
                workerId: workerId,
                workerRestAddress: SocketAddress(host: "host", port: 0)
            )
        )
        XCTAssertEqual(
            response,
            .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration)
        )
    }
    
    func test_registration_of_unknown_worker() {
        let registrar = createRegistrar()
        
        assertThrows {
            try registrar.handle(
                payload: RegisterWorkerPayload(
                    workerId: "unknown",
                    workerRestAddress: SocketAddress(host: "host", port: 0)
                )
            )
        }
    }
}

