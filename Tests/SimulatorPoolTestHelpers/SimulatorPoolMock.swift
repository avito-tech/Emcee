@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import PathLib
import SimulatorPoolModels
import Tmp
import RunnerModels

public final class SimulatorPoolMock: SimulatorPool {
    public var freedSimulatorContoller: SimulatorController?
    
    public init() {}
    
    public func allocateSimulatorController() throws -> SimulatorController {
        let controller = FakeSimulatorController(
            simulator: SimulatorFixture.simulator(),
            developerDir: .current
        )
        controller.simulatorBecameBusy()
        return controller
    }
    
    public func free(simulatorController: SimulatorController) {
        simulatorController.simulatorBecameIdle()
        freedSimulatorContoller = simulatorController
    }
    
    public func deleteSimulators() {}
    
    public func shutdownSimulators() {}
}
