import AtomicModels
import DeveloperDirLocator
import DeveloperDirModels
import FileSystem
import Foundation
import EmceeLogging
import PathLib
import PlistLib
import SimulatorPoolModels
import SynchronousWaiter
import Tmp

public final class StateMachineDrivenSimulatorController: SimulatorController, CustomStringConvertible {
    private let additionalBootAttempts: UInt
    private let bootQueue: DispatchQueue
    private let coreSimulatorStateProvider: CoreSimulatorStateProvider
    private let developerDir: DeveloperDir
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let simulatorOperationTimeouts = AtomicValue<SimulatorOperationTimeouts>(
        SimulatorOperationTimeouts(create: 30, boot: 180, delete: 20, shutdown: 20, automaticSimulatorShutdown: 3600, automaticSimulatorDelete: 7200)
    )
    private let simulatorStateMachine: SimulatorStateMachine
    private let simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor
    private let temporaryFolder: TemporaryFolder
    private let testDestination: TestDestination
    private let waiter: Waiter
    private var simulator: Simulator?

    public init(
        additionalBootAttempts: UInt,
        bootQueue: DispatchQueue,
        coreSimulatorStateProvider: CoreSimulatorStateProvider,
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        simulatorStateMachine: SimulatorStateMachine,
        simulatorStateMachineActionExecutor: SimulatorStateMachineActionExecutor,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination,
        waiter: Waiter = SynchronousWaiter()
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.bootQueue = bootQueue
        self.coreSimulatorStateProvider = coreSimulatorStateProvider
        self.developerDir = developerDir
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
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
        logger.debug("Simulator controller \(self) is now busy")
    }
    
    public func simulatorBecameIdle() {
        logger.debug("Simulator controller \(self) is now idle")
    }
    
    // MARK: - State Switching
    
    private var currentSimulatorState: SimulatorStateMachine.State {
        guard let simulator = simulator else {
            return .absent
        }
        do {
            let coreState = try coreSimulatorStateProvider.coreSimulatorState(simulator: simulator)
            switch coreState {
            case .booted, .booting:
                return .booted
            case .creating, .shutdown, .shuttingDown:
                return .created
            case .none:
                return .absent
            }
        } catch {
            logger.warning("Failed to get state for simulator \(simulator): \(error). This error will be ignored. Absent state will be returned.")
            return .absent
        }
    }

    private func attemptToSwitchState(targetStates: [SimulatorStateMachine.State]) throws {
        let actions = simulatorStateMachine.actionsToSwitchStates(
            sourceState: currentSimulatorState,
            closestStateFrom: targetStates
        )
        try perform(actions: actions)
    }

    private func perform(actions: [SimulatorStateMachine.Action]) throws {
        for action in actions {
            logger.debug("Simulator controller \(self) is performing action: \(action)")
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
            logger.debug("Simulator controller \(self) updated state to: \(currentSimulatorState)")
        }
    }
    
    private func create() throws -> Simulator {
        logger.debug("Creating simulator with \(testDestination)")

        let simulator = try simulatorStateMachineActionExecutor.performCreateSimulatorAction(
            environment: try environment(),
            testDestination: testDestination,
            timeout: simulatorOperationTimeouts.currentValue().create
        )
        logger.debug("Created simulator: \(simulator)")
        return simulator
    }
    
    private func invokeEnsuringSimulatorIsPresent(_ work: (Simulator) throws -> Void) throws {
        guard let simulator = simulator else {
            throw SimulatorError.unableToLocateSimulatorUuid
        }
        try work(simulator)
    }
    
    private func boot(simulator: Simulator) throws {
        logger.debug("Booting simulator: \(simulator)")
        
        if currentSimulatorState == .booted {
            logger.debug("Simulator \(simulator) is already booted, will not boot")
            return
        }
        
        let performBoot = {
            try self.simulatorStateMachineActionExecutor.performBootSimulatorAction(
                environment: try self.environment(),
                simulator: simulator,
                timeout: self.simulatorOperationTimeouts.currentValue().boot
            )
        }
        
        try bootQueue.sync {
            var bootAttempt = 0
            while true {
                do {
                    try performBoot()
                    logger.debug("Booted simulator \(simulator) using #\(bootAttempt + 1) attempts")
                    break
                } catch {
                    logger.error("Attempt to boot simulator \(simulator.testDestination) failed: \(error)")
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
        logger.debug("Shutting down simulator \(simulator)")
        
        if currentSimulatorState == .created {
            logger.debug("Simulator \(simulator) is shot down")
            return
        }
        
        try simulatorStateMachineActionExecutor.performShutdownSimulatorAction(
            environment: try environment(),
            simulator: simulator,
            timeout: simulatorOperationTimeouts.currentValue().shutdown
        )
    }

    private func delete(simulator: Simulator) throws {
        logger.debug("Deleting simulator \(simulator.udid)")
        
        try simulatorStateMachineActionExecutor.performDeleteSimulatorAction(
            environment: try environment(),
            simulator: simulator,
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
        let simulatorLogsPath = try fileSystem.commonlyUsedPathsProvider
            .library(inDomain: .user, create: false)
            .appending(components: ["Logs", "CoreSimulator", simulator.udid.value])
        if fileSystem.properties(forFileAtPath: simulatorLogsPath).exists() {
            logger.debug("Removing logs of simulator \(simulator)")
            try fileSystem.delete(fileAtPath: simulatorLogsPath)
        }
    }
    
    private func deleteSimulatorWorkingDirectory(simulator: Simulator) throws {
        if fileSystem.properties(forFileAtPath: simulator.path).exists() {
            logger.debug("Removing working directory of simulator \(simulator)")
            try fileSystem.delete(fileAtPath: simulator.path)
        }
    }
    
    public var description: String {
        let udid = simulator?.udid ?? UDID(value: "UNKNOWN_UDID")
        return "<\(type(of: self)) \(testDestination) \(udid) \(currentSimulatorState)>"
    }
    
    // MARK: - Envrironment
    
    private func environment() throws -> [String: String] {
        let temporaryPathComponents = ["simctl_working_dir", UUID().uuidString, "simctl_tmp"]
        let tmpdir = try temporaryFolder.pathByCreatingDirectories(components: temporaryPathComponents).pathString
        
        return try developerDirLocator.suitableEnvironment(
            forDeveloperDir: developerDir,
            byUpdatingEnvironment: ["TMPDIR": tmpdir]
        )
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
