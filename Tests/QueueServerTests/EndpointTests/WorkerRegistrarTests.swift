import DistWorkerModels
import DistWorkerModelsTestHelpers
import EmceeLogging
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueServer
import RESTMethods
import SocketModels
import TestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import XCTest

final class WorkerRegistrarTests: XCTestCase {
    lazy var alivenessTracker = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId],
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    lazy var workerConfigurations = WorkerConfigurations()
    lazy var workerId: WorkerId = "worker_id"
    
    override func setUp() {
        super.setUp()
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
    }
    
    private func createRegistrar() -> WorkerRegistrar {
        return WorkerRegistrar(
            logger: .noOp,
            workerAlivenessProvider: alivenessTracker,
            workerCapabilitiesStorage: workerCapabilitiesStorage,
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
                    workerCapabilities: [],
                    workerRestAddress: SocketAddress(host: "host", port: 0)
                )
            ),
            .workerRegisterSuccess(workerConfiguration: WorkerConfigurationFixtures.workerConfiguration))
        XCTAssertTrue(alivenessTracker.alivenessForWorker(workerId: workerId).registered)
        XCTAssertFalse(alivenessTracker.alivenessForWorker(workerId: workerId).silent)
    }
    
    func test_successful_registration() throws {
        let registrar = createRegistrar()
        
        let response = try registrar.handle(
            payload: RegisterWorkerPayload(
                workerId: workerId,
                workerCapabilities: [],
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
                    workerCapabilities: [],
                    workerRestAddress: SocketAddress(host: "host", port: 0)
                )
            )
        }
    }
}

