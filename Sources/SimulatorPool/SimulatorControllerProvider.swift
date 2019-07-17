import Foundation
import Models

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        simulator: Simulator,
        simulatorControlTool: SimulatorControlTool,
        developerDir: DeveloperDir
    ) throws -> SimulatorController
}
