@testable import SimulatorPool
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
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
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)

    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let pool = try DefaultSimulatorPool(
            developerDir: DeveloperDir.current,
            developerDirLocator: developerDirLocator,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorControllerProvider: simulatorControllerProvider,
            tempFolder: tempFolder,
            testDestination: TestDestinationFixtures.testDestination,
            testRunnerTool: .xcodebuild
        )
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Int(numberOfThreads)
        
        for _ in 0...999 {
            queue.addOperation {
                do {
                    let simulator = try pool.allocateSimulatorController()
                    let duration = TimeInterval(Float(arc4random()) / Float(UINT32_MAX) * 0.05)
                    Thread.sleep(forTimeInterval: duration)
                    pool.free(simulatorController: simulator)
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
