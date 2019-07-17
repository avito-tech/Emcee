import XCTest
import SimulatorPool
import ModelsTestHelpers
import TemporaryStuff
import SimulatorPoolTestHelpers
import SynchronousWaiter

final class SimulatorPoolConvenienceTests: XCTestCase {
    func test__simulator_allocated() throws {
        let pool = try SimulatorPoolMock()
        let allocatedSimulator = try pool.allocateSimulator()

        XCTAssertEqual(
            allocatedSimulator.simulator,
            SimulatorPoolMock.simulatorController.simulator
        )
    }

    func test__simulator_contoller_frees__upon_release() throws {
        let pool = try SimulatorPoolMock()
        let allocatedSimulator = try pool.allocateSimulator()
        allocatedSimulator.releaseSimulator()

        XCTAssertEqual(
            allocatedSimulator.simulator,
            SimulatorPoolMock.simulatorController.simulator
        )
        
        XCTAssertEqual(
            SimulatorPoolMock.simulatorController.simulator,
            (pool.freedSimulator as? FakeSimulatorController)?.simulator
        )
    }
}
