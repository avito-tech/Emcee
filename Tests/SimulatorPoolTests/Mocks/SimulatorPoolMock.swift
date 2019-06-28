@testable import SimulatorPool
import Models
import ModelsTestHelpers
import PathLib
import TemporaryStuff

class SimulatorPoolMock: SimulatorPool<FakeSimulatorController> {
    init() throws {
        simulatorController = FakeSimulatorController(
            simulator: Shimulator(
                index: 0,
                testDestination: try TestDestination(deviceType: "iPhone XL", runtime: "10.3"),
                workingDirectory: AbsolutePath.root
            ),
            fbsimctl: NonResolvableResourceLocation()
        )

        try super.init(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            fbsimctl: NonResolvableResourceLocation(),
            tempFolder: try TemporaryFolder()
        )
    }

    let simulatorController: FakeSimulatorController
    
    override func allocateSimulatorController() throws -> FakeSimulatorController {
        return simulatorController
    }

    var freedSimulator: FakeSimulatorController?
    override func freeSimulatorController(_ simulator: FakeSimulatorController) {
        freedSimulator = simulator
    }
}
