import AppleTools
import DeveloperDirLocator
import DeveloperDirModels
import EmceeLogging
import FileSystem
import Foundation
import PathLib
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import TestDestination
import Tmp

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    private let additionalBootAttempts: UInt
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let simulatorBootQueue: DispatchQueue
    private let simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    
    public init(
        additionalBootAttempts: UInt,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        simulatorBootQueue: DispatchQueue,
        simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
        self.simulatorBootQueue = simulatorBootQueue
        self.simulatorStateMachineActionExecutorProvider = simulatorStateMachineActionExecutorProvider
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        temporaryFolder: TemporaryFolder,
        testDestination: AppleTestDestination
    ) throws -> SimulatorController {
        return ActivityAwareSimulatorController(
            automaticDeleteTimePeriod: 3600,
            automaticShutdownTimePeriod: 3600,
            delegate: StateMachineDrivenSimulatorController(
                additionalBootAttempts: additionalBootAttempts,
                bootQueue: simulatorBootQueue,
                coreSimulatorStateProvider: DefaultCoreSimulatorStateProvider(),
                developerDir: developerDir,
                developerDirLocator: developerDirLocator,
                fileSystem: fileSystem,
                logger: logger,
                simulatorStateMachine: SimulatorStateMachine(),
                simulatorStateMachineActionExecutor: try simulatorStateMachineActionExecutorProvider.simulatorStateMachineActionExecutor(),
                temporaryFolder: temporaryFolder,
                testDestination: testDestination
            ),
            logger: logger
        )
    }
}
