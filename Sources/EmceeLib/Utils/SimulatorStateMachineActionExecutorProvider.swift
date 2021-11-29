import Foundation
import RunnerModels
import SimulatorPool
import SimulatorPoolModels

public protocol SimulatorStateMachineActionExecutorProvider {
    func simulatorStateMachineActionExecutor() throws -> SimulatorStateMachineActionExecutor
}
