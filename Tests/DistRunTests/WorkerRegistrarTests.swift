import DistRun
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import XCTest

final class WorkerRegistrarTests: XCTestCase {
    let alivenessTracker = WorkerAlivenessTracker(reportAliveInterval: 0.0)
    let workerConfigurations = WorkerConfigurations()
    
    private func createRegistrar() -> WorkerRegistrar {
        return WorkerRegistrar(workerConfigurations: workerConfigurations, workerAlivenessTracker: alivenessTracker)
    }
    
    func test__availability_when_worker_is_unknown() {
        let registrar = createRegistrar()
        let availability = registrar.workerConfigurationAvailability(workerId: "hello")
        XCTAssertEqual(availability, .unavailable)
    }
    
    func test_availability_when_worker_is_known() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)

        let registrar = createRegistrar()
        let availability = registrar.workerConfigurationAvailability(workerId: "worker")
        XCTAssertEqual(availability, .available(WorkerConfigurationFixtures.workerConfiguration))
    }
    
    func test_availability_when_worker_is_blocked() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        
        let registrar = createRegistrar()
        registrar.blockWorker(workerId: "worker")
        
        let availability = registrar.workerConfigurationAvailability(workerId: "worker")
        XCTAssertEqual(availability, .blocked)
    }
    
    func test_registration_for_known_worker() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        XCTAssertFalse(registrar.isWorkerRegistered(workerId: "worker"))
        
        XCTAssertNoThrow(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker")))
        XCTAssertTrue(registrar.isWorkerRegistered(workerId: "worker"))
    }
    
    func test_registration_for_blocked_worker() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        registrar.blockWorker(workerId: "worker")
        
        XCTAssertNoThrow(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker")))
        XCTAssertFalse(registrar.isWorkerRegistered(workerId: "worker"))
    }
    
    func test_is_blocked_for_blocked_worker() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        XCTAssertNoThrow(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker")))
        
        XCTAssertFalse(registrar.isWorkerBlocked(workerId: "worker"))
        registrar.blockWorker(workerId: "worker")
        XCTAssertTrue(registrar.isWorkerBlocked(workerId: "worker"))
    }
    
    func test_availability_of_registered_workers_after_last_worker_is_blocked() {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        XCTAssertNoThrow(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker")))
        XCTAssertTrue(registrar.hasAnyRegisteredWorkers)
        
        registrar.blockWorker(workerId: "worker")
        XCTAssertFalse(registrar.hasAnyRegisteredWorkers)
    }
    
    func test_successful_registration() throws {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        
        let response = try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker"))
        XCTAssertEqual(response, .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
    }
    
    func test_registration_of_blocked_worker() throws {
        workerConfigurations.add(workerId: "worker", configuration: WorkerConfigurationFixtures.workerConfiguration)
        let registrar = createRegistrar()
        registrar.blockWorker(workerId: "worker")
        
        let response = try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker"))
        XCTAssertEqual(response, .workerBlocked)
    }
    
    func test_registration_of_unknown_worker() {
        let registrar = createRegistrar()
        XCTAssertThrowsError(try registrar.handle(decodedRequest: RegisterWorkerRequest(workerId: "worker")))
    }
}

