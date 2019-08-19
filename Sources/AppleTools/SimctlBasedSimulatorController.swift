import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool

public class SimctlBasedSimulatorController: SimulatorController, CustomStringConvertible {
    private let simulator: Simulator
    private let developerDir: DeveloperDir
    private let developerDirLocator = DeveloperDirLocator()
    private let maximumBootAttempts = 2
    private static let bootQueue = DispatchQueue(label: "SimulatorBootQueue")
    private let simulatorStateMachine = SimulatorStateMachine()
    private var currentSimulatorState = SimulatorStateMachine.State.absent

    public init(
        simulator: Simulator,
        developerDir: DeveloperDir
    ) {
        self.simulator = simulator
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
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulatorSetPath,
                    "create",
                    "name", // TODO
                    simulator.testDestination.deviceType,
                    simulator.testDestination.runtime // TODO use com.apple.CoreSimulator.SimRuntime.iOS-12-2
                ],
                environment: try environment(),
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 30
                )
            )
        )
        controller.startAndListenUntilProcessDies()

        guard controller.processStatus() == .terminated(exitCode: 0) else {
            throw SimulatorBootError.createOperationFailed("simctl exit code \(controller.processStatus())")
        }
        guard let simulatorUuid = simulator.uuid else {
            throw SimulatorBootError.unableToLocateSimulatorUuid
        }
        Logger.debug("Created simulator with UUID: \(simulatorUuid.uuidString)")
    }

    private func performBootSimulatorAction() throws {
        return try SimctlBasedSimulatorController.bootQueue.sync {
            var bootAttempt = 0
            while true {
                do {
                    try bootSimulatorUsingSimctl()
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

        let shutdownController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulator.simulatorSetContainerPath,
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
        Logger.verboseDebug("Deleting simulator: \(simulator)")
        try deleteSimulatorViaSimctl()
        try attemptToDeleteSimulatorFiles()

        Logger.debug("Deleted simulator: \(simulator)")
    }

    // MARK: - Utility Methods

    private func bootSimulatorUsingSimctl() throws {
        let containerContents = try FileManager.default.contentsOfDirectory(atPath: simulator.simulatorSetContainerPath.pathString)
        let simulatorUuids = containerContents.filter { UUID(uuidString: $0) != nil }
        guard simulatorUuids.count > 0, let simulatorUuid = simulatorUuids.first else {
            throw SimulatorBootError.unableToLocateSimulatorUuid
        }

        Logger.verboseDebug("Booting simulator: \(simulator)")

        let processController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun", "simctl",
                    "--set", simulator.simulatorSetContainerPath,
                    "boot", simulatorUuid
                ],
                environment: environment()
            )
        )
        try waitForSimctlToBootSimulator(processController: processController)

        // process should be alive at this point and the boot should have finished
        guard processController.isProcessRunning else {
            throw SimulatorBootError.bootOperationFailed("simctl died unexpectedly")
        }
        Logger.debug("Booted simulator: \(simulator)")
    }

    private func waitForSimctlToBootSimulator(processController: ProcessController) throws {
        // TODO
    }

    private func attemptToDeleteSimulatorFiles() throws {
        try deleteSimulatorLogs() // must be called before deleting files in simulator working directory
        try deleteSimulatorViaSimctl()
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

    private func deleteSimulatorViaSimctl() throws {
        if let simulatorUuid = simulator.simulatorInfo.simulatorUuid {
            Logger.debug("Deleting simulator \(simulatorUuid)")
            let deleteController = try ProcessController(
                subprocess: Subprocess(
                    arguments: [
                        "/usr/bin/xcrun", "simctl",
                        "--set", simulator.simulatorSetContainerPath,
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
        return "<simctl: \(simulator), developer dir: \(developerDir)>"
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
