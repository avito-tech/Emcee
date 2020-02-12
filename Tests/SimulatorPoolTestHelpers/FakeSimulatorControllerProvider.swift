import Foundation
import Models
import SimulatorPool

public final class FakeSimulatorControllerProvider: SimulatorControllerProvider {
    public var result: (TestDestination) -> SimulatorController
    
    public init(result: @escaping (TestDestination) -> SimulatorController) {
        self.result = result
    }
    
    public func createSimulatorController(
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool
    ) throws -> SimulatorController {
        return result(testDestination)
    }
}
