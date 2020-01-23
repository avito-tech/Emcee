import AppleTools
import DeveloperDirLocator
import Foundation
import Models
import PathLib
import SimulatorPool
import TemporaryStuff
import fbxctest

public final class DefaultSimulatorControllerProvider: SimulatorControllerProvider {
    
    private let additionalBootAttempts: UInt
    private let simulatorBootQueue: DispatchQueue
    private let simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    
    public init(
        additionalBootAttempts: UInt,
        simulatorBootQueue: DispatchQueue,
        simulatorStateMachineActionExecutorProvider: SimulatorStateMachineActionExecutorProvider
    ) {
        self.additionalBootAttempts = additionalBootAttempts
        self.simulatorBootQueue = simulatorBootQueue
        self.simulatorStateMachineActionExecutorProvider = simulatorStateMachineActionExecutorProvider
    }

    public func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorControlTool: SimulatorControlTool,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController {
        return StateMachineDrivenSimulatorController(
            additionalBootAttempts: additionalBootAttempts,
            bootQueue: simulatorBootQueue,
            developerDir: developerDir,
            developerDirLocator: developerDirLocator,
            simulatorOperationTimeouts: SimulatorOperationTimeouts(
                create: 30,
                boot: 180,
                delete: 20,
                shutdown: 20
            ),
            simulatorStateMachine: SimulatorStateMachine(),
            simulatorStateMachineActionExecutor: try simulatorStateMachineActionExecutorProvider.simulatorStateMachineActionExecutor(
                simulatorControlTool: simulatorControlTool,
                testRunnerTool: testRunnerTool
            ),
            testDestination: testDestination
        )
    }
}
