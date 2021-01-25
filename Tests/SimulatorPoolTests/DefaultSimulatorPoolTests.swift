@testable import SimulatorPool
import DeveloperDirModels
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import Tmp
import TestHelpers
import XCTest

class DefaultSimulatorPoolTests: XCTestCase {
    
    var tempFolder = try! TemporaryFolder()
    lazy var simulatorControllerProvider = FakeSimulatorControllerProvider { testDestination -> SimulatorController in
        return FakeSimulatorController(
            simulator: SimulatorFixture.simulator(),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: .current
        )
    }
    lazy var pool = assertDoesNotThrow {
        try DefaultSimulatorPool(
            developerDir: DeveloperDir.current,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder,
            testDestination: TestDestinationFixtures.testDestination
        )
    }
    
    func test___simulator_is_busy___after_allocation() throws {
        guard let controller = try pool.allocateSimulatorController() as? FakeSimulatorController else {
            return XCTFail("Unexpected type of controller")
        }
        XCTAssertTrue(controller.isBusy)
    }
    
    func test___simulator_is_free___after_freeing_it() throws {
        guard let controller = try pool.allocateSimulatorController() as? FakeSimulatorController else {
            return XCTFail("Unexpected type of controller")
        }
        pool.free(simulatorController: controller)
        
        XCTAssertFalse(controller.isBusy)
    }
}
