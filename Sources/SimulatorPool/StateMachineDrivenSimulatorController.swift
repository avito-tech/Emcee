import AtomicModels
import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import SimulatorPoolModels
import SynchronousWaiter
import TemporaryStuff

public final class StateMachineDrivenSimulatorController: SimulatorController, CustomStringConvertible {
    private let additionalBootAttempts: UInt
    private let bootQueue: DispatchQueue
    private let developerDir: DeveloperDir
    private let developerDirLocator: DeveloperDirLocator
    private let simulatorOperationTimeouts = AtomicValue<SimulatorOperationTimeouts>(
        SimulatorOperationTimeouts(create: 30, boot: 180, delete: 20, shutdown: 20, automaticSimulatorShutdown: 3600, automaticSimulatorDelete: 7200)
    )
    private let simulatorStateMachine: SimulatorStateMachine
    private let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
    private let temporaryFolder: TemporaryFolder
    private let testDestination: TestDestination
    private let waiter: Waiter
    private var currentSimulatorState = SimulatorStateMachine.State.absent
    private var simulator: Simulator?

    public init(
        additionalBootAttempts: UInt,
        bootQueue: DispatchQueue,
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorStateMachine: SimulatorStateMachine,
        simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination,
        waiter: Waiter = SynchronousWaiter()
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.bootQueue = bootQueue
        self.developerDir = developerDir
        self.developerDirLocator = developerDirLocator
        self.simulatorStateMachine = simulatorStateMachine
        self.simulatorStateMachineActionExecutor = simulatorStateMachineActionExecutor
        self.temporaryFolder = temporaryFolder
        self.testDestination = testDestination
        self.waiter = waiter
    }
    
    // MARK: - SimulatorController
    
    public func apply(simulatorOperationTimeouts: SimulatorOperationTimeouts) {
        self.simulatorOperationTimeouts.set(simulatorOperationTimeouts)
    }
    
    public func bootedSimulator() throws -> Simulator {
        try attemptToSwitchState(targetStates: [.booted])
        
        guard let simulator = simulator else {
            throw SimulatorError.unableToLocateSimulatorUuid
        }
        return simulator
    }

    public func deleteSimulator() throws {
        try attemptToSwitchState(targetStates: [.absent])
    }

    public func shutdownSimulator() throws {
        try attemptToSwitchState(targetStates: [.created, .absent])
    }
    
    public func simulatorBecameBusy() {
        Logger.debug("Simulator controller \(self) is now busy")
    }
    
    public func simulatorBecameIdle() {
        Logger.debug("Simulator controller \(self) is now idle")
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
                simulator = try create()
            case .boot:
                try invokeEnsuringSimulatorIsPresent(boot)
            case .shutdown:
                try invokeEnsuringSimulatorIsPresent(shutdown)
            case .delete:
                try invokeEnsuringSimulatorIsPresent(delete)
                simulator = nil
            }
            currentSimulatorState = action.resultingState
        }
    }
    
    private func create() throws -> Simulator {
        Logger.verboseDebug("Creating simulator with \(testDestination)")

        let simulator = try simulatorStateMachineActionExecutor.performCreateSimulatorAction(
            environment: try environment(),
            testDestination: testDestination,
            timeout: simulatorOperationTimeouts.currentValue().create
        )
        Logger.debug("Created simulator: \(simulator)")
        return simulator
    }
    
    private func invokeEnsuringSimulatorIsPresent(_ work: (Simulator) throws -> Void) throws {
        guard let simulator = simulator else {
            throw SimulatorError.unableToLocateSimulatorUuid
        }
        try work(simulator)
    }
    
    private func boot(simulator: Simulator) throws {
        Logger.verboseDebug("Booting simulator: \(simulator)")
        
        let performBoot = {
            try self.simulatorStateMachineActionExecutor.performBootSimulatorAction(
                environment: try self.environment(),
                path: simulator.path,
                simulatorUuid: simulator.udid,
                timeout: self.simulatorOperationTimeouts.currentValue().boot
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
                    Logger.error("Attempt to boot simulator \(simulator.testDestination) failed: \(error)")
                    bootAttempt += 1
                    if bootAttempt < 1 + additionalBootAttempts {
                        waiter.wait(timeout: Double(bootAttempt) * 3.0, description: "Time gap between reboot attempts")
                    } else {
                        throw error
                    }
                }
            }
        }

    }
    
    private func shutdown(simulator: Simulator) throws {
        Logger.debug("Shutting down simulator \(simulator)")
        
        try simulatorStateMachineActionExecutor.performShutdownSimulatorAction(
            environment: try environment(),
            path: simulator.path,
            simulatorUuid: simulator.udid,
            timeout: simulatorOperationTimeouts.currentValue().shutdown
        )
    }

    private func delete(simulator: Simulator) throws {
        Logger.debug("Deleting simulator \(simulator.udid)")
        
        try simulatorStateMachineActionExecutor.performDeleteSimulatorAction(
            environment: try environment(),
            path: simulator.path,
            simulatorUuid: simulator.udid,
            timeout: simulatorOperationTimeouts.currentValue().delete
        )
        
        try attemptToDeleteSimulatorFiles(simulator: simulator)
    }
    
    private func attemptToDeleteSimulatorFiles(simulator: Simulator) throws {
        try deleteSimulatorWorkingDirectory(simulator: simulator)
        try deleteSimulatorLogs(simulator: simulator)
    }
    
    private func deleteSimulatorLogs(
        simulator: Simulator
    ) throws {
        let simulatorLogsPath = ("~/Library/Logs/CoreSimulator/" as NSString)
            .expandingTildeInPath
            .appending(pathComponent: simulator.udid.value)
        if FileManager.default.fileExists(atPath: simulatorLogsPath) {
            Logger.verboseDebug("Removing logs of simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulatorLogsPath)
        }
    }
    
    private func deleteSimulatorWorkingDirectory(simulator: Simulator) throws {
        if FileManager.default.fileExists(atPath: simulator.path.pathString) {
            Logger.verboseDebug("Removing working directory of simulator \(simulator)")
            try FileManager.default.removeItem(atPath: simulator.path.pathString)
        }
    }
    
    public var description: String {
        return "<\(type(of: self)) \(testDestination) \(currentSimulatorState)>"
    }
    
    // MARK: - Envrironment
    
    private func environment() throws -> [String: String] {
        let temporaryPathComponents = ["fbsimctl_working_dir", UUID().uuidString, "fbsimctl_tmp"]
        let tmpdir = try temporaryFolder.pathByCreatingDirectories(components: temporaryPathComponents).pathString
        
        return [
            "DEVELOPER_DIR": try developerDirLocator.path(developerDir: developerDir).pathString,
            "TMPDIR": tmpdir
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
