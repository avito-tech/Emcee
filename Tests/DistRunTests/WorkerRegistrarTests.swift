import DistRun
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import WorkerAlivenessTracker
import XCTest

final class WorkerRegistrarTests: XCTestCase {
    let alivenessTracker = WorkerAlivenessTracker(reportAliveInterval: .infinity)
    let workerConfigurations = WorkerConfigurations()
    let workerId = "worker_id"
    
    override func setUp() {
        super.setUp()
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    private func createRegistrar() -> WorkerRegistrar {
        return WorkerRegistrar(workerConfigurations: workerConfigurations, workerAlivenessTracker: alivenessTracker)
    }
    
    func test_registration_for_known_worker() throws {
        let registrar = createRegistrar()
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId), .notRegistered)
        
        XCTAssertEqual(
            try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: workerId)),
            .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId), .alive)
    }
    
    func test_registration_for_blocked_worker() throws {
        let registrar = createRegistrar()
        alivenessTracker.didRegisterWorker(workerId: workerId)
        alivenessTracker.didBlockWorker(workerId: workerId)
        
        XCTAssertEqual(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: workerId)), .workerBlocked)
    }
    
    func test_successful_registration() throws {
        let registrar = createRegistrar()
        
        let response = try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: workerId))
        XCTAssertEqual(response, .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
    }
    
    func test_registration_of_unknown_worker() {
        let registrar = createRegistrar()
        XCTAssertThrowsError(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "unknown")))
    }
}

