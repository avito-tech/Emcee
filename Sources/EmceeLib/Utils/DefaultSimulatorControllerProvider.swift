import AppleTools
import DeveloperDirLocator
import DeveloperDirModels
import Foundation
import PathLib
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import Tmp
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    private let additionalBootAttempts: UInt
    private let developerDirLocator: DeveloperDirLocator
    private let simulatorBootQueue: DispatchQueue
    private let simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    
    public init(
        additionalBootAttempts: UInt,
        developerDirLocator: DeveloperDirLocator,
        simulatorBootQueue: DispatchQueue,
        simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.developerDirLocator = developerDirLocator
        self.simulatorBootQueue = simulatorBootQueue
        self.simulatorStateMachineActionExecutorProvider = simulatorStateMachineActionExecutorProvider
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination
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
                simulatorStateMachine: SimulatorStateMachine(),
                simulatorStateMachineActionExecutor: try simulatorStateMachineActionExecutorProvider.simulatorStateMachineActionExecutor(
                    simulatorControlTool: simulatorControlTool
                ),
                temporaryFolder: temporaryFolder,
                testDestination: testDestination
            )
        )
    }
}
