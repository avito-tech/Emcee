import Foundation
import Models

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController
}
