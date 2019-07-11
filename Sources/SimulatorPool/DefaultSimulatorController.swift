import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import fbxctest
import ProcessController
import ResourceLocationResolver

/**
 * Prepares and returns the simulator it owns. API is expected to be used from non multithreaded environment,
 * i.e. from serial queue.
 */
public class DefaultSimulatorController: SimulatorController, CustomStringConvertible {
    private let simulator: Simulator
    private let developerDir: DeveloperDir
    private let developerDirLocator = DeveloperDirLocator()
    private let fbsimctl: ResolvableResourceLocation
    private let maximumBootAttempts = 2
    private var simulatorKeepAliveProcessController: ProcessController?
    private static let bootQueue = DispatchQueue(label: "SimulatorBootQueue")
    private let simulatorStateMachine = SimulatorStateMachine()
    private var currentSimulatorState = SimulatorStateMachine.State.absent

    required public init(
        simulator: Simulator,
        fbsimctl: ResolvableResourceLocation,
        developerDir: DeveloperDir
    ) {
        self.simulator = simulator
        self.fbsimctl = fbsimctl
        self.developerDir = developerDir
    }

    public func bootedSimulator() throws -> Simulator {
        try attemptToSwitchState(targetStates: [.booted])
        return simulator
    }

    public func deleteSimulator() throws {
        try attemptToSwitchState(targetStates: [.absent])
    }

    public func shutdownSimulator() throws {
        try attemptToSwitchState(targetStates: [.created, .absent])
    }

    // MARK: - States

    private func attemptToSwitchState(targetStates: [SimulatorStateMachine.State]) throws {
        let actions = simulatorStateMachine.actionsToSwitchStates(
            sourceState: currentSimulatorState,
            closestStateFrom: targetStates
        )
        try perform(actions: actions)
    }

    private func perform(actions: [SimulatorStateMachine.Action]) throws {
        for action in actions {
            Logger.debug("Performing action: \(action)")
            switch action {
            case .create:
                try performCreateSimulatorAction()
            case .boot:
                try performBootSimulatorAction()
            case .shutdown:
                try performShutdownSimulatorAction()
            case .delete:
                try performDeleteSimulatorAction()
            }
            currentSimulatorState = action.resultingState
        }
    }

    private func performCreateSimulatorAction() throws {
        Logger.verboseDebug("Creating simulator: \(simulator)")
        let simulatorSetPath = simulator.simulatorSetContainerPath
        try FileManager.default.createDirectory(atPath: simulatorSetPath, withIntermediateDirectories: true)
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulatorSetPath,
                    "create",
                    "iOS \(simulator.testDestination.runtime)", simulator.testDestination.deviceType
                ],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 30
                )
            )
        )
        controller.startAndListenUntilProcessDies()

        guard controller.processStatus() == .terminated(exitCode: 0) else {
            throw SimulatorBootError.createOperationFailed("fbsimctl exit code \(controller.processStatus())")
        }
        guard let simulatorUuid = simulator.uuid else {
            throw SimulatorBootError.unableToLocateSimulatorUuid
        }
        Logger.debug("Created simulator with UUID: \(simulatorUuid.uuidString)")
    }

    private func performBootSimulatorAction() throws {
        return try DefaultSimulatorController.bootQueue.sync {
            var bootAttempt = 0
            while true {
                do {
                    try bootSimulatorUsingFbsimctl()
                    Logger.debug("Booted simulator \(simulator) using #\(bootAttempt + 1) attempts")
                    break
                } catch {
                    Logger.error("Attempt to boot simulator \(simulator.testDestination.destinationString) failed: \(error)")
                    bootAttempt += 1
                    if bootAttempt < maximumBootAttempts {
                        let waitBetweenAttemptsToBoot = 5.0
                        Logger.warning("Waiting \(waitBetweenAttemptsToBoot) seconds before attempting to boot again")
                        Thread.sleep(forTimeInterval: waitBetweenAttemptsToBoot)
                    } else {
                        throw error
                    }
                }
            }
        }
    }

    private func performShutdownSimulatorAction() throws {
        guard let simulatorUuid = simulator.simulatorInfo.simulatorUuid else {
            Logger.debug("Cannot shutdown simulator, no UUID: \(simulator)")
            return
        }
        Logger.debug("Shutting down simulator \(simulatorUuid)")

        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil

        let shutdownController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl", "--set", simulator.simulatorSetContainerPath,
                    "shutdown", simulatorUuid.uuidString
                ],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 20
                )
            )
        )
        shutdownController.startAndListenUntilProcessDies()
    }

    private func performDeleteSimulatorAction() throws {
        if let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController {
            simulatorKeepAliveProcessController.interruptAndForceKillIfNeeded()
            simulatorKeepAliveProcessController.waitForProcessToDie()
        }
        simulatorKeepAliveProcessController = nil

        Logger.verboseDebug("Deleting simulator: \(simulator)")
        try deleteSimulatorUsingFbsimctl()
        try attemptToDeleteSimulatorFiles()

        Logger.debug("Deleted simulator: \(simulator)")
    }

    // MARK: - Utility Methods

    private func bootSimulatorUsingFbsimctl() throws {
        let containerContents = try FileManager.default.contentsOfDirectory(atPath: simulator.simulatorSetContainerPath.pathString)
        let simulatorUuids = containerContents.filter { UUID(uuidString: $0) != nil }
        guard simulatorUuids.count > 0, let simulatorUuid = simulatorUuids.first else {
            throw SimulatorBootError.unableToLocateSimulatorUuid
        }

        Logger.verboseDebug("Booting simulator: \(simulator)")

        // we keep this process alive throughout the run, as it owns the simulator process.
        simulatorKeepAliveProcessController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulator.simulatorSetContainerPath,
                    simulatorUuid, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"
                ],
                environment: [
                    "DEVELOPER_DIR": try developerDirLocator.path(developerDir: developerDir).pathString
                ]
            )
        )
        try waitForFbsimctlToBootSimulator()

        // process should be alive at this point and the boot should have finished
        guard simulatorKeepAliveProcessController?.isProcessRunning == true else {
            throw SimulatorBootError.bootOperationFailed("Simulator keep-alive process died unexpectedly")
        }
        Logger.debug("Booted simulator: \(simulator)")
    }

    private func waitForFbsimctlToBootSimulator() throws {
        guard let simulatorKeepAliveProcessController = simulatorKeepAliveProcessController else {
            Logger.error("Expected to have keep-alive process")
            throw SimulatorBootError.bootOperationFailed("No keep-alive process found")
        }
        let outputProcessor = FbsimctlOutputProcessor(processController: simulatorKeepAliveProcessController)
        do {
            try outputProcessor.waitForEvent(type: .ended, name: .boot, timeout: 90)
        } catch {
            Logger.error("Simulator \(simulator.testDestination.destinationString) did not boot in time: \(error)")
            throw error
        }

        do {
            try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: 50)
        } catch {
            Logger.error("Boot operation for simulator \(simulator.testDestination.destinationString) did not finish: \(error)")
            throw error
        }
    }

    private func deleteSimulatorUsingFbsimctl() throws {
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctl.asArgumentWith(packageName: PackageName.fbsimctl),
                    "--json", "--set", simulator.simulatorSetContainerPath,
                    "--simulators", "delete"
                ],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 30
                )
            )
        )
        controller.startAndListenUntilProcessDies()
    }

    private func attemptToDeleteSimulatorFiles() throws {
        if let simulatorUuid = simulator.simulatorInfo.simulatorUuid {
            Logger.debug("Deleting simulator \(simulatorUuid)")
            let deleteController = try ProcessController(
                subprocess: Subprocess(
                    arguments: [
                        "/usr/bin/xcrun",
                        "simctl", "--set", simulator.simulatorSetContainerPath,
                        "delete", simulatorUuid.uuidString
                    ],
                    silenceBehavior: SilenceBehavior(
                        automaticAction: .interruptAndForceKill,
                        allowedSilenceDuration: 15
                    )
                )
            )
            deleteController.startAndListenUntilProcessDies()
        }

        if FileManager.default.fileExists(atPath: simulator.simulatorSetContainerPath.pathString) {
            Logger.verboseDebug("Removing files left by simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulator.simulatorSetContainerPath.pathString)
        }
    }

    // MARK: - Protocols

    public func hash(into hasher: inout Hasher) {
        hasher.combine(simulator)
        hasher.combine(developerDir)
    }

    public static func == (left: DefaultSimulatorController, right: DefaultSimulatorController) -> Bool {
        return left.simulator == right.simulator
            && left.developerDir == right.developerDir
    }

    public var description: String {
        return "Controller for simulator \(simulator), developer dir: \(developerDir)"
    }

    // MARK: - Errors

    private enum SimulatorBootError: Error, CustomStringConvertible {
        case createOperationFailed(String)
        case unableToLocateSimulatorUuid
        case bootOperationFailed(String)

        var description: String {
            switch self {
            case .createOperationFailed(let message):
                return "Failed to create simulator: \(message)"
            case .unableToLocateSimulatorUuid:
                return "Failed to boot simulator: failed to locate simulator's UUID"
            case .bootOperationFailed(let message):
                return "Failed to boot simulator: \(message)"
            }
        }
    }
}
