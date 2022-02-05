import DeveloperDirModels
import Foundation
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import TestDestination
import Tmp

public final class FakeSimulatorControllerProvider: SimulatorControllerProvider {
    public var result: (AppleTestDestination) -> SimulatorController
    
    public init(result: @escaping (AppleTestDestination) -> SimulatorController) {
        self.result = result
    }
    
    public func createSimulatorController(
        developerDir: DeveloperDir,
        temporaryFolder: TemporaryFolder,
        testDestination: AppleTestDestination
    ) throws -> SimulatorController {
        return result(testDestination)
    }
}
