import DeveloperDirModels
import Foundation
import SimulatorPoolModels
import Tmp

public protocol SimulatorControllerProvider {
    func createSimulatorController(
        developerDir: DeveloperDir,
        simDeviceType: SimDeviceType,
        simRuntime: SimRuntime,
        temporaryFolder: TemporaryFolder
    ) throws -> SimulatorController
}
