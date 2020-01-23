import DeveloperDirLocator
import Foundation
import Models

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulatorControlTool: SimulatorControlTool,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController
}
