import DeveloperDirModels
import Foundation
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import Tmp

public final class FakeSimulatorControllerProvider: SimulatorControllerProvider {
    public var result: (SimDeviceType, SimRuntime) -> SimulatorController
    
    public init(result: @escaping (SimDeviceType, SimRuntime) -> SimulatorController) {
        self.result = result
    }
    
    public func createSimulatorController(
        developerDir: DeveloperDir,
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        temporaryFolder: TemporaryFolder
    ) throws -> SimulatorController {
        return result(simDeviceType, simRuntime)
    }
}
