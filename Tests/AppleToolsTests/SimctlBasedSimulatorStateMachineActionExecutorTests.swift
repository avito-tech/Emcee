import AppleTools
import Foundation
import PathLib
import Models
import ModelsTestHelpers
import ProcessController
import ProcessControllerTestHelpers
import TemporaryStuff
import XCTest

final class SimctlBasedSimulatorStateMachineActionExecutorTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
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
            _ = try executor.performCreateSimulatorAction(
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
                
                let pathToStdout = try self.tempFolder.createFile(filename: "stdout.txt")
                
                controller.subprocess = Subprocess(
                    arguments: subprocess.arguments,
                    standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                        stdoutContentsFile: pathToStdout
                    )
                )
                return controller
            },
            simulatorSetPath: tempFolder.absolutePath
        )
        
        assertThrows {
            _ = try executor.performCreateSimulatorAction(
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
                controller.overridedProcessStatus = ProcessStatus.terminated(exitCode: 0)
                
                let pathToStdout = try self.tempFolder.createFile(
                    filename: "stdout.txt",
                    contents: expectedUdid.data(using: .utf8)
                )
                
                controller.subprocess = Subprocess(
                    arguments: subprocess.arguments,
                    standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                        stdoutContentsFile: pathToStdout
                    )
                )
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
    
    func test___simctl_args() {
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
            _ = try executor.performCreateSimulatorAction(
                environment: [:],
                testDestination: assertDoesNotThrow { try TestDestination(deviceType: "iPhone SE", runtime: "11.3") },
                timeout: 60
            )
        }
    }
}
