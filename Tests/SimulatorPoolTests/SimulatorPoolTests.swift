import Models
import ModelsTestHelpers
@testable import SimulatorPool
import ResourceLocationResolver
import SynchronousWaiter
import TempFolder
import XCTest

class SimulatorPoolTests: XCTestCase {
    
    var tempFolder: TempFolder!
    
    override func setUp() {
        XCTAssertNoThrow(tempFolder = try TempFolder())
    }
    
    func testThrowingError() throws {
        let pool = try SimulatorPool<DefaultSimulatorController>(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            fbsimctl: NonResolvableResourceLocation(),
            tempFolder: tempFolder)
        _ = try pool.allocateSimulatorController()
        XCTAssertThrowsError(_ = try pool.allocateSimulatorController(), "Expected to throw") { error in
            XCTAssertEqual(error as? BorrowError, BorrowError.noSimulatorsLeft)
        }
    }
    
    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let pool = try SimulatorPool<DefaultSimulatorController>(
            numberOfSimulators: UInt(numberOfThreads),
            testDestination: TestDestinationFixtures.testDestination,
            fbsimctl: NonResolvableResourceLocation(),
            tempFolder: tempFolder)
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
        let pool = try SimulatorPool<FakeSimulatorController>(
            numberOfSimulators: 1,
            testDestination: TestDestinationFixtures.testDestination,
            fbsimctl: NonResolvableResourceLocation(),
            tempFolder: tempFolder,
            automaticCleanupTiumeout: 1)
        let simulatorController = try pool.allocateSimulatorController()
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
