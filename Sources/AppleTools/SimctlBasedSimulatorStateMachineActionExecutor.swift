import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPool

public final class SimctlBasedSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor, CustomStringConvertible {

    private let simulatorSetPath: AbsolutePath

    public init(simulatorSetPath: AbsolutePath) {
        self.simulatorSetPath = simulatorSetPath
    }
    
    public var description: String {
        return "simctl with set path \(simulatorSetPath)"
    }
    
    public func performCreateSimulatorAction(
        environment: [String: String],
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws -> Simulator {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
                    "create",
                    "Emcee Sim \(testDestination.deviceType) \(testDestination.runtime)",
                    "com.apple.CoreSimulator.SimDeviceType." + testDestination.deviceType.replacingOccurrences(of: " ", with: "."),
                    "com.apple.CoreSimulator.SimRuntime.iOS-" + testDestination.runtime.replacingOccurrences(of: ".", with: "-")
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: timeout
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        
        let udid: UDID = UDID(
            value: try String(contentsOf: controller.subprocess.standardStreamsCaptureConfig.stdoutContentsFile.fileUrl, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        return Simulator(
            testDestination: testDestination,
            udid: udid,
            path: simulatorSetPath.appending(component: udid.value))
    }
    
    public func performBootSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let processController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", path.removingLastComponent,
                    "bootstatus", simulatorUuid.value,
                    "-bd"
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: timeout
                )
            )
        )
        processController.startAndListenUntilProcessDies()
    }
    
    public func performShutdownSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let shutdownController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", path.removingLastComponent,
                    "shutdown", simulatorUuid.value
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: timeout
                )
            )
        )
        shutdownController.startAndListenUntilProcessDies()
    }
    
    public func performDeleteSimulatorAction(
        environment: [String: String],
        path: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let deleteController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", path.removingLastComponent,
                    "delete", simulatorUuid.value
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: timeout
                )
            )
        )
        deleteController.startAndListenUntilProcessDies()
    }
}
