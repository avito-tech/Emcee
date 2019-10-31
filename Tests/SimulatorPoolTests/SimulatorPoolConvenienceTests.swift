import XCTest
import SimulatorPool
import ModelsTestHelpers
import TemporaryStuff
import SimulatorPoolTestHelpers
import SynchronousWaiter

final class SimulatorPoolConvenienceTests: XCTestCase {
    func test__simulator_contoller_frees__upon_release() throws {
        let pool = SimulatorPoolMock()
        let allocatedSimulator = try pool.allocateSimulator()
        allocatedSimulator.releaseSimulator()
        
        XCTAssertEqual(
            allocatedSimulator.simulator,
            (pool.freedSimulatorContoller as? FakeSimulatorController)?.simulator
        )
    }
}
