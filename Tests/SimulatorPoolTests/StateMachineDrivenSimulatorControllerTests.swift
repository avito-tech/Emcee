import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import PathLib
import SimulatorPool
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
import TestHelpers
import XCTest

final class StateMachineDrivenSimulatorControllerTests: XCTestCase {
    private let expectedDeveloperDirPath = AbsolutePath("/tmp/some/dev/dir")
    private let expectedSimulatorPath = AbsolutePath("/tmp/some/simulator/path")
    private let expectedTestDestination = TestDestinationFixtures.testDestination
    private let expectedTimeout: TimeInterval = 42.0
    private let expectedUdid = UDID(value: "some_UDID")
    
    func test___if_create_throws___boot_fails() {
        let controller = assertDoesNotThrow {
            try createController(
                create: { throw ErrorForTestingPurposes(text: "Expected error") },
                timeouts: createTimeouts()
            )
        }
        
        assertThrows {
            _ = try controller.bootedSimulator()
        }
    }
    
    func test___if_boot_throws___boot_fails() {
        let controller = assertDoesNotThrow {
            try createController(
                boot: { throw ErrorForTestingPurposes(text: "Expected error") },
                timeouts: createTimeouts()
            )
        }
        
        assertThrows {
            _ = try controller.bootedSimulator()
        }
    }
    
    func test___if_delete_throws___delete_fails() {
        let controller = assertDoesNotThrow {
            try createController(
                delete: { throw ErrorForTestingPurposes(text: "Expected error") },
                timeouts: createTimeouts()
            )
        }
        
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
        assertThrows {
            try controller.deleteSimulator()
        }
    }
    
    func test___if_shutdown_throws___shutdown_fails() {
        let controller = assertDoesNotThrow {
            try createController(
                shutdown: { throw ErrorForTestingPurposes(text: "Expected error") },
                timeouts: createTimeouts()
            )
        }
        
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
        assertThrows {
            try controller.shutdownSimulator()
        }
    }
    
    func test___create_gets_expected_arguments() {
        let controller = assertDoesNotThrow {
            try createController(
                additionalBootAttempts: 0,
                actionExecutor: FakeSimulatorStateMachineActionExecutor(
                    create: { (environment, testDestination, timeout) -> Simulator in
                        XCTAssertEqual(environment["DEVELOPER_DIR"], self.expectedDeveloperDirPath.pathString)
                        XCTAssertEqual(testDestination, self.expectedTestDestination)
                        XCTAssertEqual(timeout, self.expectedTimeout)
                        
                        return self.createSimulator(environment: environment, testDestination: testDestination, timeout: timeout)
                    }
                ),
                developerDirLocator: FakeDeveloperDirLocator(result: expectedDeveloperDirPath),
                timeouts: createTimeouts(create: expectedTimeout)
            )
        }
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
    }
    
    func test___boot_gets_expected_arguments() {
        let controller = assertDoesNotThrow {
            try createController(
                additionalBootAttempts: 0,
                actionExecutor: FakeSimulatorStateMachineActionExecutor(
                    create: createSimulator,
                    boot: validateArguments
                ),
                developerDirLocator: FakeDeveloperDirLocator(result: expectedDeveloperDirPath),
                timeouts: createTimeouts(boot: expectedTimeout)
            )
        }
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
    }
    
    func test___delete_gets_expected_arguments() {
        let controller = assertDoesNotThrow {
            try createController(
                additionalBootAttempts: 0,
                actionExecutor: FakeSimulatorStateMachineActionExecutor(
                    create: createSimulator,
                    delete: validateArguments
                ),
                developerDirLocator: FakeDeveloperDirLocator(result: expectedDeveloperDirPath),
                timeouts: createTimeouts(delete: expectedTimeout)
            )
        }
        
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
        assertDoesNotThrow {
            try controller.deleteSimulator()
        }
    }
    
    func test___shutdown_gets_expected_arguments() {
        let controller = assertDoesNotThrow {
            try createController(
                additionalBootAttempts: 0,
                actionExecutor: FakeSimulatorStateMachineActionExecutor(
                    create: createSimulator,
                    shutdown: validateArguments
                ),
                developerDirLocator: FakeDeveloperDirLocator(result: expectedDeveloperDirPath),
                timeouts: createTimeouts(shutdown: expectedTimeout)
            )
        }
        
        assertDoesNotThrow {
            _ = try controller.bootedSimulator()
        }
        assertDoesNotThrow {
            try controller.deleteSimulator()
        }
    }
    
    func test___boot_performs_multiple_attempts() {
        var numberOfPerformedAttempts: UInt = 0
        let additionalBootAttempts: UInt = 4
        let expectedNumberOfPerformedAttempts = additionalBootAttempts + 1
        
        let controller = assertDoesNotThrow {
            try createController(
                additionalBootAttempts: additionalBootAttempts,
                boot: {
                    numberOfPerformedAttempts += 1
                    throw ErrorForTestingPurposes(text: "Expected error")
                }
            )
        }
        
        assertThrows {
            _ = try controller.bootedSimulator()
        }
        XCTAssertEqual(numberOfPerformedAttempts, expectedNumberOfPerformedAttempts)
    }
    
    private func validateArguments(
        environment: [String: String],
        path: AbsolutePath,
        udid: UDID,
        timeout: TimeInterval
    ) {
        XCTAssertEqual(environment["DEVELOPER_DIR"], expectedDeveloperDirPath.pathString)
        XCTAssertEqual(path, expectedSimulatorPath)
        XCTAssertEqual(udid, expectedUdid)
        XCTAssertEqual(timeout, expectedTimeout)
    }
    
    private func createController(
        additionalBootAttempts: UInt = 2,
        create: @escaping () throws -> () = {},
        boot: @escaping () throws -> () = {},
        delete: @escaping () throws -> () = {},
        shutdown: @escaping () throws -> () = {},
        timeouts: SimulatorOperationTimeouts = SimulatorOperationTimeouts(
            create: .infinity,
            boot: .infinity,
            delete: .infinity,
            shutdown: .infinity,
            automaticSimulatorShutdown: .infinity,
            automaticSimulatorDelete: .infinity
        )
    ) throws -> StateMachineDrivenSimulatorController {
        let tempFolder = assertDoesNotThrow {
            try TemporaryFolder()
        }
        return try createController(
            additionalBootAttempts: additionalBootAttempts,
            actionExecutor: FakeSimulatorStateMachineActionExecutor(
                create: { environment, testDestination, timeout in
                    try create()
                    return self.createSimulator(environment: environment, testDestination: testDestination, timeout: timeout)
                },
                boot: { _, _, _, _ in try boot() },
                shutdown: { _, _, _, _ in try shutdown() },
                delete: { _, _, _, _ in try delete() }
            ),
            developerDirLocator: FakeDeveloperDirLocator(result: tempFolder.absolutePath),
            timeouts: timeouts
        )
    }
    
    private func createController(
        additionalBootAttempts: UInt,
        actionExecutor: SimulatorStateMachineActionExecutor,
        developerDirLocator: DeveloperDirLocator,
        timeouts: SimulatorOperationTimeouts
    ) throws -> StateMachineDrivenSimulatorController {
        let controller = StateMachineDrivenSimulatorController(
            additionalBootAttempts: additionalBootAttempts,
            bootQueue: DispatchQueue(label: "serial"),
            developerDir: .current,
            developerDirLocator: developerDirLocator,
            simulatorStateMachine: SimulatorStateMachine(),
            simulatorStateMachineActionExecutor: actionExecutor,
            temporaryFolder: try TemporaryFolder(),
            testDestination: expectedTestDestination,
            waiter: NoOpWaiter()
        )
        controller.apply(simulatorOperationTimeouts: timeouts)
        return controller
    }
    
    private func createTimeouts(
        create: TimeInterval = .infinity,
        boot: TimeInterval = .infinity,
        delete: TimeInterval = .infinity,
        shutdown: TimeInterval = .infinity,
        automaticSimulatorShutdown: TimeInterval = .infinity,
        automaticSimulatorDelete: TimeInterval = .infinity
    ) -> SimulatorOperationTimeouts {
        return SimulatorOperationTimeouts(
            create: create,
            boot: boot,
            delete: delete,
            shutdown: shutdown,
            automaticSimulatorShutdown: automaticSimulatorShutdown,
            automaticSimulatorDelete: automaticSimulatorDelete
        )
    }
    
    private func createSimulator(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) -> Simulator {
        return Simulator(
            testDestination: testDestination,
            udid: expectedUdid,
            path: expectedSimulatorPath
        )
    }
}
