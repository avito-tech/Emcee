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

    public init() {}
    
    public var description: String {
        return "simctl"
    }
    
    public func performCreateSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws {
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
    }
    
    public func performBootSimulatorAction(
        environment: [String: String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let processController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
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
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let shutdownController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
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
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let deleteController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
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
