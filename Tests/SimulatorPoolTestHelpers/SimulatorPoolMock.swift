@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import PathLib
import TemporaryStuff

public final class SimulatorPoolMock: SimulatorPool {
    public var freedSimulatorContoller: SimulatorController?
    
    public init() {}
    
    public func allocateSimulatorController() throws -> SimulatorController {
        return FakeSimulatorController(
            simulator: SimulatorFixture.simulator(),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: .current
        )
    }
    
    public func free(simulatorController: SimulatorController) {
        freedSimulatorContoller = simulatorController
    }
    
    public func deleteSimulators() {}
    
    public func shutdownSimulators() {}
}
