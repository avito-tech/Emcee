import XCTest
import SimulatorPool
import ModelsTestHelpers
import TempFolder
import SynchronousWaiter

final class SimulatorPoolConvenienceTests: XCTestCase {
    func test__simulator_allocated() throws {
        let pool = try SimulatorPoolMock()

        let allocatedSimulator = try pool.allocateSimulator()

        XCTAssertEqual(allocatedSimulator.simulator, pool.simulatorController.simulator)
    }

    func test__simulator_contoller_frees__upon_release() throws {
        let pool = try SimulatorPoolMock()

        let allocatedSimulator = try pool.allocateSimulator()
        allocatedSimulator.releaseSimulator()

        XCTAssertEqual(allocatedSimulator.simulator, pool.simulatorController.simulator)
        XCTAssertEqual(pool.simulatorController, pool.freedSimulator)
    }
}
