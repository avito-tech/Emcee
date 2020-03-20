import XCTest
import SimulatorPool
import ModelsTestHelpers
import TemporaryStuff
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import SynchronousWaiter

final class SimulatorPoolConvenienceTests: XCTestCase {
    private let simulatorOperationTimeouts = SimulatorOperationTimeouts(create: 1, boot: 2, delete: 3, shutdown: 4, automaticSimulatorShutdown: 5, automaticSimulatorDelete: 6)
    
    func test__simulator_contoller_frees__upon_release() throws {
        let pool = SimulatorPoolMock()
        let allocatedSimulator = try pool.allocateSimulator(simulatorOperationTimeouts: simulatorOperationTimeouts)
        allocatedSimulator.releaseSimulator()
        
        guard let fakeSimulatorController = pool.freedSimulatorContoller as? FakeSimulatorController else {
            return XCTFail("Unexpected behaviour")
        }
        
        XCTAssertEqual(
            allocatedSimulator.simulator,
            fakeSimulatorController.simulator
        )
        XCTAssertEqual(
            fakeSimulatorController.simulatorOperationTimeouts,
            simulatorOperationTimeouts
        )
    }
}
