import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class WorkerRegistrarTests: XCTestCase {
    let alivenessTracker = WorkerAlivenessProviderFixtures.alivenessTrackerWithAlwaysAliveResults()
    let workerConfigurations = WorkerConfigurations()
    let workerId: WorkerId = "worker_id"
    
    override func setUp() {
        super.setUp()
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    private func createRegistrar() -> WorkerRegistrar {
        return WorkerRegistrar(workerConfigurations: workerConfigurations, workerAlivenessProvider: alivenessTracker)
    }
    
    func test_registration_for_known_worker() throws {
        let registrar = createRegistrar()
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId).status, .notRegistered)
        
        XCTAssertEqual(
            try registrar.handle(decodedPayload: RegisterWorkerPayload(workerId: workerId)),
            .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId).status, .alive)
    }
    
    func test___registration_for_blocked_worker__throws() throws {
        let registrar = createRegistrar()
        alivenessTracker.didRegisterWorker(workerId: workerId)
        alivenessTracker.blockWorker(workerId: workerId)
        
        XCTAssertThrowsError(try registrar.handle(decodedPayload: RegisterWorkerPayload(workerId: workerId)))
    }
    
    func test_successful_registration() throws {
        let registrar = createRegistrar()
        
        let response = try registrar.handle(decodedPayload: RegisterWorkerPayload(workerId: workerId))
        XCTAssertEqual(response, .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
    }
    
    func test_registration_of_unknown_worker() {
        let registrar = createRegistrar()
        XCTAssertThrowsError(try registrar.handle(decodedPayload: RegisterWorkerPayload(workerId: "unknown")))
    }
}

