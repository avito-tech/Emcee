import DeveloperDirModels
import Foundation
import Models
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws -> SimulatorController
}
