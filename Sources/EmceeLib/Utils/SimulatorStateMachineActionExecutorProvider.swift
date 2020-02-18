import Foundation
import Models
import RunnerModels
import SimulatorPool
import SimulatorPoolModels

public protocol SimulatorStateMachineActionExecutorProvider {
    func simulatorStateMachineActionExecutor(
        simulatorControlTool: SimulatorControlTool,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorStateMachineActionExecutor
}
