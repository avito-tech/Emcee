@testable import SimulatorPool
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
import TestHelpers
import XCTest

class DefaultSimulatorPoolTests: XCTestCase {
    
    var tempFolder = try! TemporaryFolder()
    let simulatorOperationTimeouts = SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts()
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
            testDestination: TestDestinationFixtures.testDestination,
            testRunnerTool: .xcodebuild
        )
    }
    
    func test___simulator_is_busy___after_allocation() throws {
        guard let controller = try pool.allocateSimulatorController(simulatorOperationTimeouts: simulatorOperationTimeouts) as? FakeSimulatorController else {
            return XCTFail("Unexpected type of controller")
        }
        XCTAssertTrue(controller.isBusy)
    }
    
    func test___simulator_is_free___after_freeing_it() throws {
        guard let controller = try pool.allocateSimulatorController(simulatorOperationTimeouts: simulatorOperationTimeouts) as? FakeSimulatorController else {
            return XCTFail("Unexpected type of controller")
        }
        pool.free(simulatorController: controller)
        
        XCTAssertFalse(controller.isBusy)
    }

    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Int(numberOfThreads)
        
        for _ in 0...999 {
            queue.addOperation {
                let simulator = self.assertDoesNotThrow {
                    try self.pool.allocateSimulatorController(simulatorOperationTimeouts: self.simulatorOperationTimeouts)
                }
                let duration = TimeInterval(Float(arc4random()) / Float(UINT32_MAX) * 0.05)
                Thread.sleep(forTimeInterval: duration)
                self.pool.free(simulatorController: simulator)
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(
            pool.numberExistingOfControllers(),
            numberOfThreads
        )
    }
}
