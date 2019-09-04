import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import SynchronousWaiter

/**
 * Prepares and returns the simulator it owns. API is expected to be used from non multithreaded environment,
 * i.e. from serial queue.
 */
public class FbsimctlBasedSimulatorController: SimulatorController, CustomStringConvertible {
    private let simulator: Simulator
    private let developerDir: DeveloperDir
    private let developerDirLocator = DeveloperDirLocator()
    private let fbsimctl: ResolvableResourceLocation
    private let maximumBootAttempts = 2
    private var simulatorKeepAliveProcessController: ProcessController?
    private static let bootQueue = DispatchQueue(label: "SimulatorBootQueue")
    private let simulatorStateMachine = SimulatorStateMachine()
    private var currentSimulatorState = SimulatorStateMachine.State.absent

    public init(
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
                    fbsimctlArg,
                    "--json", "--set", simulatorSetPath,
                    "create",
                    "iOS \(simulator.testDestination.runtime)", simulator.testDestination.deviceType
                ],
                environment: try environment(),
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 60
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
        return try FbsimctlBasedSimulatorController.bootQueue.sync {
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
                        SynchronousWaiter.wait(timeout: Double(bootAttempt) * 3.0, description: "Time gap between reboot attempts")
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
                environment: try environment(),
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
                    fbsimctlArg,
                    "--json", "--set", simulator.simulatorSetContainerPath,
                    simulatorUuid, "boot",
                    "--locale", "ru_US",
                    "--direct-launch", "--", "listen"
                ],
                environment: environment()
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
            try outputProcessor.waitForEvent(type: .ended, name: .boot, timeout: 180)
        } catch {
            Logger.error("Simulator \(simulator.testDestination.destinationString) did not boot in time: \(error)")
            throw error
        }

        do {
            try outputProcessor.waitForEvent(type: .started, name: .listen, timeout: 60)
        } catch {
            Logger.error("Boot operation for simulator \(simulator.testDestination.destinationString) did not finish: \(error)")
            throw error
        }
    }

    private func deleteSimulatorUsingFbsimctl() throws {
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    fbsimctlArg,
                    "--json", "--set", simulator.simulatorSetContainerPath,
                    "--simulators", "delete"
                ],
                environment: try environment(),
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 30
                )
            )
        )
        controller.startAndListenUntilProcessDies()
    }

    private func attemptToDeleteSimulatorFiles() throws {
        try deleteSimulatorLogs() // must be called before deleting files in simulator working directory
        try deleteSimulatorViaXcrun()
        try deleteSimulatorSetContainer()
        try deleteSimulatorWorkingDirectory()
    }
    
    // MARK: - Deletion
    
    private func deleteSimulatorLogs() throws {
        if let simulatorLogsPath = simulatorLogsPath(simulator: simulator) {
            if FileManager.default.fileExists(atPath: simulatorLogsPath) {
                Logger.verboseDebug("Removing logs of simulator \(simulator)")
                try FileManager.default.removeItem(atPath: simulatorLogsPath)
            }
        }
    }
    
    private func simulatorLogsPath(simulator: Simulator) -> String? {
        guard let uuid = simulator.uuid else {
            Logger.warning("Couldn't get simulator uuid to get path to logs of simulator \(simulator)")
            return nil
        }
        
        let pathString = ("~/Library/Logs/CoreSimulator/" as NSString)
            .expandingTildeInPath
            .appending(pathComponent: uuid.uuidString)
        
        return pathString
    }
    
    private func deleteSimulatorSetContainer() throws {
        if FileManager.default.fileExists(atPath: simulator.simulatorSetContainerPath.pathString) {
            Logger.verboseDebug("Removing files left by simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulator.simulatorSetContainerPath.pathString)
        }
    }
    private func deleteSimulatorWorkingDirectory() throws {
        if FileManager.default.fileExists(atPath: simulator.workingDirectory.pathString) {
            Logger.verboseDebug("Removing working directory of simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulator.workingDirectory.pathString)
        }
    }
    
    private func deleteSimulatorViaXcrun() throws {
        if let simulatorUuid = simulator.simulatorInfo.simulatorUuid {
            Logger.debug("Deleting simulator \(simulatorUuid)")
            let deleteController = try ProcessController(
                subprocess: Subprocess(
                    arguments: [
                        "/usr/bin/xcrun",
                        "simctl", "--set", simulator.simulatorSetContainerPath,
                        "delete", simulatorUuid.uuidString
                    ],
                    environment: try environment(),
                    silenceBehavior: SilenceBehavior(
                        automaticAction: .interruptAndForceKill,
                        allowedSilenceDuration: 15
                    )
                )
            )
            deleteController.startAndListenUntilProcessDies()
        }
    }
    
    private func environment() throws -> [String: String] {
        return [
            "DEVELOPER_DIR": try developerDirLocator.path(developerDir: developerDir).pathString
        ]
    }

    public var description: String {
        return "<fbsimctl: \(simulator), developer dir: \(developerDir)>"
    }
    
    private var fbsimctlArg: SubprocessArgument {
        return fbsimctl.asArgumentWith(implicitFilenameInArchive: "fbsimctl")
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
