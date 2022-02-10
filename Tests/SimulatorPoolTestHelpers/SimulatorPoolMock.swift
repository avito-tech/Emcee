@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import PathLib
import SimulatorPoolModels
import Tmp

public final class SimulatorPoolMock: SimulatorPool {
    public var freedSimulatorContoller: SimulatorController?
    
    public init() {}
    
    public func allocateSimulatorController() throws -> SimulatorController {
        let controller = FakeSimulatorController(
            simulator: SimulatorFixture.simulator(
                path: "/tmp/DOES_NOT_MATTER"
            ),
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
