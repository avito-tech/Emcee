import Foundation
import Models
import RunnerModels
import SimulatorPoolModels

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController
}
