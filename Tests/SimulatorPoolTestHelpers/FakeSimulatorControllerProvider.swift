import DeveloperDirLocator
import Foundation
import Models
import SimulatorPool

public final class FakeSimulatorControllerProvider: SimulatorControllerProvider {
    public var result: (Simulator) -> SimulatorController
    
    public init(result: @escaping (Simulator) -> SimulatorController) {
        self.result = result
    }
    
    public func createSimulatorController(
        developerDir: DeveloperDir,
        developerDirLocator: DeveloperDirLocator,
        simulator: Simulator,
        simulatorControlTool: SimulatorControlTool
    ) throws -> SimulatorController {
        return result(simulator)
    }
}
