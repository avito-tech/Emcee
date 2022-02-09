@testable import SimulatorPool
import DeveloperDirModels
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TestHelpers
import Tmp
import XCTest

class DefaultSimulatorPoolTests: XCTestCase {
    
    private lazy var tempFolder = assertDoesNotThrow {
        try TemporaryFolder()
    }
    private lazy var simulatorControllerProvider = FakeSimulatorControllerProvider { [tempFolder] simDeviceType, simRuntime -> SimulatorController in
        return FakeSimulatorController(
            simulator: SimulatorFixture.simulator(
                simDeviceType: simDeviceType,
                simRuntime: simRuntime,
                path: tempFolder.absolutePath
            ),
            developerDir: .current
        )
    }
    private lazy var pool = DefaultSimulatorPool(
        developerDir: DeveloperDir.current,
        logger: .noOp,
        simulatorControllerProvider: simulatorControllerProvider,
        simDeviceType: SimDeviceTypeFixture.fixture(),
        simRuntime: SimRuntimeFixture.fixture(),
        tempFolder: tempFolder
    )
    
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
