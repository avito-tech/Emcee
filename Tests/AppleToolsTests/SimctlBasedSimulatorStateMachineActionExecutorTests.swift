import AppleTools
import Foundation
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import Tmp
import XCTest

final class SimctlBasedSimulatorStateMachineActionExecutorTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private let udid = UDID(value: UUID().uuidString)
    private lazy var pathToSimulator = assertDoesNotThrow {
        try tempFolder.createDirectory(components: [udid.value])
    }
    private lazy var simulator = Simulator(
        testDestination: TestDestinationFixtures.testDestination,
        udid: udid,
        path: pathToSimulator
    )
    
    func test___when_simctl_finished_with_non_zero_code___create_throws() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 1)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        assertThrows {
            try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: TestDestinationFixtures.testDestination,
                timeout: 60
            )
        }
    }
    
    func test___when_simctl_does_not_return_udid___create_throws() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 0)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: TestDestinationFixtures.testDestination,
                timeout: 60
            )
        }
    }
    
    func test___when_simctl_returns_udid___creates_simulator() {
        let expectedUdid = UUID().uuidString
        
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.onStart { _, unsubscribe in
                    controller.broadcastStdout(data: Data(expectedUdid.utf8))
                    controller.overridedProcessStatus = .terminated(exitCode: 0)
                    unsubscribe()
                }
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertDoesNotThrow {
            let simulator = try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: TestDestinationFixtures.testDestination,
                timeout: 60
            )
            XCTAssertEqual(simulator.testDestination, TestDestinationFixtures.testDestination)
            XCTAssertEqual(simulator.udid, UDID(value: expectedUdid))
            XCTAssertEqual(simulator.simulatorSetPath, tempFolder.absolutePath)
        }
    }
    
    func test___when_simctl_returns_udid___new_lines_ignored() {
        let expectedUdid = UUID().uuidString + "\n"
        
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.onStart { _, unsubscribe in
                    controller.broadcastStdout(data: Data(expectedUdid.utf8))
                    controller.overridedProcessStatus = .terminated(exitCode: 0)
                    unsubscribe()
                }
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertDoesNotThrow {
            let simulator = try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: TestDestinationFixtures.testDestination,
                timeout: 60
            )
            XCTAssertEqual(simulator.udid, UDID(value: expectedUdid.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }
    
    func test___create_simulator_simctl_args() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    [
                        "/usr/bin/xcrun", "simctl",
                        "--set", self.tempFolder.absolutePath.pathString,
                        "create", "Emcee Sim iPhone SE 11.3",
                        "com.apple.CoreSimulator.SimDeviceType.iPhone-SE",
                        "com.apple.CoreSimulator.SimRuntime.iOS-11-3"
                    ]
                )
                
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 1)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: assertDoesNotThrow { try TestDestination(deviceType: "iPhone SE", runtime: "11.3") },
                timeout: 60
            )
        }
    }
    
    func test___boot_simulator_simctl_args() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    [
                        "/usr/bin/xcrun", "simctl",
                        "--set", self.pathToSimulator.removingLastComponent.pathString,
                        "bootstatus", self.udid.value,
                        "-bd"
                    ]
                )
                
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 0)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertDoesNotThrow {
            try executor.performBootSimulatorAction(
                environment: [:],
                simulator: Simulator(testDestination: TestDestinationFixtures.testDestination, udid: udid, path: pathToSimulator),
                timeout: 10
            )
        }
    }
    
    func test___boot_simulator_throws___if_simctl_fails() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 1)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            try executor.performBootSimulatorAction(
                environment: [:],
                simulator: simulator,
                timeout: 10
            )
        }
    }
    
    func test___shutdown_simulator_simctl_args() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    [
                        "/usr/bin/xcrun", "simctl",
                        "--set", self.pathToSimulator.removingLastComponent.pathString,
                        "shutdown", self.udid.value
                    ]
                )
                
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 0)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertDoesNotThrow {
            try executor.performShutdownSimulatorAction(
                environment: [:],
                simulator: simulator,
                timeout: 10
            )
        }
    }
    
    func test___shutdown_simulator_throws___if_simctl_fails() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 1)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            try executor.performShutdownSimulatorAction(
                environment: [:],
                simulator: simulator,
                timeout: 10
            )
        }
    }
    
    func test___delete_simulator_simctl_args() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    [
                        "/usr/bin/xcrun", "simctl",
                        "--set", self.pathToSimulator.removingLastComponent.pathString,
                        "delete", self.udid.value
                    ]
                )
                
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 0)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertDoesNotThrow {
            try executor.performDeleteSimulatorAction(
                environment: [:],
                simulator: simulator,
                timeout: 10
            )
        }
    }
    
    func test___delete_simulator_throws___if_simctl_fails() {
        let executor = SimctlBasedSimulatorStateMachineActionExecutor(
            processControllerProvider: FakeProcessControllerProvider { subprocess in
                let controller = FakeProcessController(subprocess: subprocess)
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 1)
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            try executor.performDeleteSimulatorAction(
                environment: [:],
                simulator: simulator,
                timeout: 10
            )
        }
    }
}
