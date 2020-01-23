import Foundation
import Models
import SimulatorPool

public protocol SimulatorStateMachineActionExecutorProvider {
    func simulatorStateMachineActionExecutor(
        simulatorControlTool: SimulatorControlTool,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorStateMachineActionExecutor
}
