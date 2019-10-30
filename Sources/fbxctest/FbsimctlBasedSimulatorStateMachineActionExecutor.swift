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
        testDestination: TestDestination,
        timeout: TimeInterval
    ) throws {
        let processController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    "create",
                    "iOS \(testDestination.runtime)", testDestination.deviceType
                ],
                environment: environment
            )
        )

        let fbsimctlEvents = try waitForFbsimctlToCreateSimulator(
            processController: processController,
            timeout: timeout
        )
        let createEndedEvents = fbsimctlEvents.compactMap { $0 as? FbSimCtlCreateEndedEvent }
        guard createEndedEvents.count == 1, let createEndedEvent = createEndedEvents.first else {
            throw FbsimctlError.createOperationFailed("Failed to get single create ended event")
        }
        Logger.debug("Created simulator with UUID: \(createEndedEvent.subject.udid)")
    }
    
    public func performBootSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        let processController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    simulatorUuid.value, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"
                ],
                environment: environment
            )
        )
        try waitForFbsimctlToBootSimulator(
            processController: processController,
            timeout: timeout
        )

        // process should be alive at this point and the boot should have finished
        guard processController.isProcessRunning == true else {
            throw FbsimctlError.bootOperationFailed("Simulator keep-alive process died unexpectedly")
        }

        // we keep this process alive throughout the run, as it owns the simulator process.
        simulatorKeepAliveProcessController = processController
    }
    
    public func performShutdownSimulatorAction(
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil

        let shutdownController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl", "--set", simulatorSetPath,
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
        environment: [String : String],
        simulatorSetPath: AbsolutePath,
        simulatorUuid: UDID,
        timeout: TimeInterval
    ) throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    "--simulators", "delete"
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

    // MARK: - Utility Methods

    private func waitForFbsimctlToCreateSimulator(
        processController: ProcessController,
        timeout: TimeInterval
    ) throws -> [FbSimCtlEventCommonFields] {
        let outputProcessor = FbsimctlOutputProcessor(processController: processController)
        return try outputProcessor.waitForEvent(type: .ended, name: .create, timeout: timeout)
    }

    private func waitForFbsimctlToBootSimulator(
        processController: ProcessController,
        timeout: TimeInterval
    ) throws {
        let outputProcessor = FbsimctlOutputProcessor(processController: processController)
        try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: timeout)
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
