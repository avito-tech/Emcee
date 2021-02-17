import DateProviderTestHelpers
import MetricsExtensions
import MetricsTestHelpers
import QueueModels
import SimulatorPool
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import SynchronousWaiter
import Tmp
import XCTest

final class SimulatorPoolConvenienceTests: XCTestCase {
    private lazy var dateProvider = DateProviderFixture()
    private lazy var simulatorOperationTimeouts = SimulatorOperationTimeouts(create: 1, boot: 2, delete: 3, shutdown: 4, automaticSimulatorShutdown: 5, automaticSimulatorDelete: 6)
    private lazy var version = Version(value: "version")
    
    func test__simulator_contoller_frees__upon_release() throws {
        let pool = SimulatorPoolMock()
        let allocatedSimulator = try pool.allocateSimulator(
            dateProvider: dateProvider,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: GlobalMetricRecorderImpl()
        )
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
