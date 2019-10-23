@testable import SimulatorPool
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
import XCTest

class SimulatorPoolTests: XCTestCase {
    
    var tempFolder = try! TemporaryFolder()
    let simulatorControllerProvider = FakeSimulatorControllerProvider { (simulator) -> SimulatorController in
        return FakeSimulatorController(
            simulator: simulator,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: .current
        )
    }
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)

    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let pool = try SimulatorPool(
            developerDir: DeveloperDir.current,
            developerDirLocator: developerDirLocator,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder,
            testDestination: TestDestinationFixtures.testDestination
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
                    XCTFail("Unexpected exception has been thrown: \(error)")
                }
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(
            pool.numberExistingOfControllers(),
            numberOfThreads
        )
    }
}
