@testable import SimulatorPool
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
import XCTest

class SimulatorPoolTests: XCTestCase {
    
    var tempFolder: TemporaryFolder!
    let simulatorControllerProvider = FakeSimulatorControllerProvider { (simulator) -> SimulatorController in
        return FakeSimulatorController(
            simulator: simulator,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: .current
        )
    }
    
    override func setUp() {
        XCTAssertNoThrow(tempFolder = try TemporaryFolder())
    }
    
    func testThrowingError() throws {
        let pool = try SimulatorPool(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: DeveloperDir.current,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder
        )
        _ = try pool.allocateSimulatorController()
        XCTAssertThrowsError(_ = try pool.allocateSimulatorController(), "Expected to throw") { error in
            XCTAssertEqual(error as? BorrowError, BorrowError.noSimulatorsLeft)
        }
    }
    
    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let pool = try SimulatorPool(
            numberOfSimulators: UInt(numberOfThreads),
            testDestination: TestDestinationFixtures.testDestination,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: DeveloperDir.current,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder
        )
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Int(numberOfThreads)
        
        for _ in 0...999 {
            queue.addOperation {
                do {
                    let simulator = try pool.allocateSimulatorController()
                    let duration = TimeInterval(Float(arc4random()) / Float(UINT32_MAX) * 0.05)
                    Thread.sleep(forTimeInterval: duration)
                    pool.freeSimulatorController(simulator)
                } catch {
                    XCTFail("No exception should be thrown")
                }
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
    }
    
    func test___automatic_cleanup_shuts_down_simulators() throws {
        let pool = try SimulatorPool(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: DeveloperDir.current,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder,
            automaticCleanupTiumeout: 1
        )
        let simulatorController = try pool.allocateSimulatorController() as! FakeSimulatorController
        pool.freeSimulatorController(simulatorController)
        
        try SynchronousWaiter.waitWhile(
            pollPeriod: 0.01,
            timeout: SynchronousWaiter.Timeout(description: "Automatic cleanup", value: 2)) {
                simulatorController.didCallShutdown == false
        }
        
        XCTAssertTrue(simulatorController.didCallShutdown, "Simulator should be automatically cleaned after timeout")
        XCTAssertFalse(simulatorController.didCallDelete, "Simulator should not be deleted when cleaning up resources")
    }
}
