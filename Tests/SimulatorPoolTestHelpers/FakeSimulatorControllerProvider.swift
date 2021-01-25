import DeveloperDirModels
import Foundation
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import Tmp

public final class FakeSimulatorControllerProvider: SimulatorControllerProvider {
    public var result: (TestDestination) -> SimulatorController
    
    public init(result: @escaping (TestDestination) -> SimulatorController) {
        self.result = result
    }
    
    public func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        temporaryFolder: TemporaryFolder,
        testDestination: TestDestination
    ) throws -> SimulatorController {
        return result(testDestination)
    }
}
