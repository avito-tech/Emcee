import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPool

public final class FbsimctlBasedSimulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor, CustomStringConvertible {
    private let fbsimctl: ResolvableResourceLocation
    private var simulatorKeepAliveProcessController: ProcessController?

    public init(fbsimctl: ResolvableResourceLocation) {
        self.fbsimctl = fbsimctl
    }

    public func performCreateSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        testDestination: TestDestination
    ) throws {
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    "create",
                    "iOS \(testDestination.runtime)", testDestination.deviceType
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 60
                )
            )
        )
        controller.startAndListenUntilProcessDies()

        guard controller.processStatus() == .terminated(exitCode: 0) else {
            throw FbsimctlError.createOperationFailed("fbsimctl exit code \(controller.processStatus())")
        }
    }
    
    public func performBootSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws {
        // we keep this process alive throughout the run, as it owns the simulator process.
        simulatorKeepAliveProcessController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    simulatorUuid, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"
                ],
                environment: environment
            )
        )
        try waitForFbsimctlToBootSimulator()

        // process should be alive at this point and the boot should have finished
        guard simulatorKeepAliveProcessController?.isProcessRunning == true else {
            throw FbsimctlError.bootOperationFailed("Simulator keep-alive process died unexpectedly")
        }
    }
    
    public func performShutdownSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil

        let shutdownController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl", "--set", simulatorSetPath,
                    "shutdown", simulatorUuid
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 20
                )
            )
        )
        shutdownController.startAndListenUntilProcessDies()
    }
    
    public func performDeleteSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: String
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil
        
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    "--simulators", "delete"
                ],
                environment: environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 30
                )
            )
        )
        controller.startAndListenUntilProcessDies()
    }

    // MARK: - Utility Methods

    private func waitForFbsimctlToBootSimulator() throws {
        guard let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController else {
            Logger.error("Expected to have keep-alive process")
            throw FbsimctlError.bootOperationFailed("No keep-alive process found")
        }
        let outputProcessor = FbsimctlOutputProcessor(processController: simulatorKeepAliveProcessController)
        try outputProcessor.waitForEvent(type: .ended, name: .boot, timeout: 180)
        try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: 60)
    }

    public var description: String {
        return "fbsimctl"
    }
    
    private var fbsimctlArg: SubprocessArgument {
        return fbsimctl.asArgumentWith(implicitFilenameInArchive: "fbsimctl")
    }

    // MARK: - Errors

    private enum FbsimctlError: Error, CustomStringConvertible {
        case createOperationFailed(String)
        case bootOperationFailed(String)

        var description: String {
            switch self {
            case .createOperationFailed(let message):
                return "Failed to create simulator: \(message)"
            case .bootOperationFailed(let message):
                return "Failed to boot simulator: \(message)"
            }
        }
    }
}
