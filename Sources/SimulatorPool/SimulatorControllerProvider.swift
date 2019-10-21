import DeveloperDirLocator
import Foundation
import Models

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulator: Simulator,
        simulatorControlTool: SimulatorControlTool
    ) throws -> SimulatorController
}
