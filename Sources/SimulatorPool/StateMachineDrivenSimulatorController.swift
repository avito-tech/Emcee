import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import SynchronousWaiter

public final class StateMachineDrivenSimulatorController: SimulatorController {
    public final class SimulatorOperationTimeouts {
        public let create: TimeInterval
        public let boot: TimeInterval
        public let delete: TimeInterval
        public let shutdown: TimeInterval

        public init(create: TimeInterval, boot: TimeInterval, delete: TimeInterval, shutdown: TimeInterval) {
            self.create = create
            self.boot = boot
            self.delete = delete
            self.shutdown = shutdown
        }
    }
    
    private let bootQueue: DispatchQueue
    private let developerDir: DeveloperDir
    private let developerDirLocator: DeveloperDirLocator
    private let maximumBootAttempts: UInt
    private let simulator: Simulator
    private let simulatorOperationTimeouts: SimulatorOperationTimeouts
    private let simulatorStateMachine: SimulatorStateMachine
    private let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
    private var currentSimulatorState = SimulatorStateMachine.State.absent

    public init(
        bootQueue: DispatchQueue,
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        maximumBootAttempts: UInt,
        simulator: Simulator,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorStateMachine: SimulatorStateMachine,
        simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
    ) {
        self.bootQueue = bootQueue
        self.developerDir = developerDir
        self.developerDirLocator = developerDirLocator
        self.maximumBootAttempts = maximumBootAttempts
        self.simulator = simulator
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorStateMachine = simulatorStateMachine
        self.simulatorStateMachineActionExecutor = simulatorStateMachineActionExecutor
    }
    
    // MARK: - SimulatorController
    
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
    
    // MARK: - State Switching

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
                try create()
            case .boot:
                try boot()
            case .shutdown:
                try shutdown()
            case .delete:
                try delete()
            }
            currentSimulatorState = action.resultingState
        }
    }
    
    private func create() throws {
        Logger.verboseDebug("Creating simulator: \(simulator)")
        let simulatorSetPath = simulator.simulatorSetContainerPath
        try FileManager.default.createDirectory(atPath: simulatorSetPath, withIntermediateDirectories: true)

        try simulatorStateMachineActionExecutor.performCreateSimulatorAction(
            environment: try environment(),
            simulatorSetPath: simulatorSetPath,
            testDestination: simulator.testDestination,
            timeout: simulatorOperationTimeouts.create
        )
        
        guard let simulatorUuid = simulator.uuid else {
            throw SimulatorError.unableToLocateSimulatorUuid
        }
        Logger.debug("Created simulator with UUID: \(simulatorUuid)")
    }
    
    private func boot() throws {
        let containerContents = try FileManager.default.contentsOfDirectory(atPath: simulator.simulatorSetContainerPath.pathString)
        let simulatorUuids = containerContents.filter { UUID(uuidString: $0) != nil }
        guard simulatorUuids.count > 0, let simulatorUuid = simulatorUuids.first else {
            throw SimulatorError.unableToLocateSimulatorUuid
        }

        Logger.verboseDebug("Booting simulator: \(simulator)")
        
        let performBoot = {
            try self.simulatorStateMachineActionExecutor.performBootSimulatorAction(
                environment: try self.environment(),
                simulatorSetPath: self.simulator.simulatorSetContainerPath,
                simulatorUuid: UDID(value: simulatorUuid),
                timeout: self.simulatorOperationTimeouts.boot
            )
        }
        
        try bootQueue.sync {
            var bootAttempt = 0
            while true {
                do {
                    try performBoot()
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
    
    private func shutdown() throws {
        guard let simulatorUuid = simulator.simulatorInfo.simulatorUuid else {
            Logger.debug("Cannot shutdown simulator, no UUID: \(simulator)")
            return
        }
        Logger.debug("Shutting down simulator \(simulatorUuid)")
        
        try simulatorStateMachineActionExecutor.performShutdownSimulatorAction(
            environment: try environment(),
            simulatorSetPath: simulator.simulatorSetContainerPath,
            simulatorUuid: simulatorUuid,
            timeout: simulatorOperationTimeouts.shutdown
        )
    }

    private func delete() throws {
        guard let simulatorUuid = simulator.simulatorInfo.simulatorUuid else {
            Logger.debug("Cannot delete simulator, no UUID: \(simulator)")
            return
        }
        Logger.debug("Deleting simulator \(simulatorUuid)")
        
        try simulatorStateMachineActionExecutor.performDeleteSimulatorAction(
            environment: try environment(),
            simulatorSetPath: simulator.simulatorSetContainerPath,
            simulatorUuid: simulatorUuid,
            timeout: simulatorOperationTimeouts.delete
        )
        
        try attemptToDeleteSimulatorFiles(
            simulatorUuid: simulatorUuid
        )
    }
    
    private func attemptToDeleteSimulatorFiles(
        simulatorUuid: UDID
    ) throws {
        try deleteSimulatorSetContainer()
        try deleteSimulatorWorkingDirectory()
        try deleteSimulatorLogs(simulatorUuid: simulatorUuid)
    }
    
    private func deleteSimulatorLogs(
        simulatorUuid: UDID
    ) throws {
        let simulatorLogsPath = ("~/Library/Logs/CoreSimulator/" as NSString)
            .expandingTildeInPath
            .appending(pathComponent: simulatorUuid.value)
        if FileManager.default.fileExists(atPath: simulatorLogsPath) {
            Logger.verboseDebug("Removing logs of simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulatorLogsPath)
        }
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
    
    // MARK: - Envrironment
    
    private func environment() throws -> [String: String] {
        return [
            "DEVELOPER_DIR": try developerDirLocator.path(developerDir: developerDir).pathString
        ]
    }
    
    // MARK: - Errors
    
    private enum SimulatorError: Error, CustomStringConvertible {
        case unableToLocateSimulatorUuid

        var description: String {
            switch self {
            case .unableToLocateSimulatorUuid:
                return "Failed to boot simulator: failed to locate simulator's UUID"
            }
        }
    }
}
