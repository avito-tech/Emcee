import DeveloperDirModels
import Foundation
import RunnerModels
import SimulatorPoolModels
import Tmp

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws -> SimulatorController
}
