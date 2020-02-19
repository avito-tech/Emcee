import AppleTools
import DeveloperDirLocator
import Foundation
import Models
import PathLib
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import TemporaryStuff
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    private let additionalBootAttempts: UInt
    private let automaticSimulatorShutdown: TimeInterval
    private let developerDirLocator: DeveloperDirLocator
    private let simulatorBootQueue: DispatchQueue
    private let simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    
    public init(
        additionalBootAttempts: UInt,
        automaticSimulatorShutdown: TimeInterval,
        developerDirLocator: DeveloperDirLocator,
        simulatorBootQueue: DispatchQueue,
        simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.automaticSimulatorShutdown = automaticSimulatorShutdown
        self.developerDirLocator = developerDirLocator
        self.simulatorBootQueue = simulatorBootQueue
        self.simulatorStateMachineActionExecutorProvider = simulatorStateMachineActionExecutorProvider
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController {
        return ActivityAwareSimulatorController(
            automaticShutdownTimePeriod: automaticSimulatorShutdown,
            delegate: StateMachineDrivenSimulatorController(
                additionalBootAttempts: additionalBootAttempts,
                bootQueue: simulatorBootQueue,
                developerDir: developerDir,
                developerDirLocator: developerDirLocator,
                simulatorOperationTimeouts: simulatorOperationTimeouts,
                simulatorStateMachine: SimulatorStateMachine(),
                simulatorStateMachineActionExecutor: try simulatorStateMachineActionExecutorProvider.simulatorStateMachineActionExecutor(
                    simulatorControlTool: simulatorControlTool,
                    testRunnerTool: testRunnerTool
                ),
                testDestination: testDestination
            )
        )
    }
}
