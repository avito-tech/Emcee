import Models
@testable import SimulatorPool
import SynchronousWaiter
import XCTest

class SimulatorPoolTests: XCTestCase {
    
    func testThrowingError() throws {
        let pool = SimulatorPool<DefaultSimulatorController>(
            numberOfSimulators: 1,
            testDestination: try TestDestination(deviceType: "", iOSVersion: "11.0"),
            auxiliaryPaths: AuxiliaryPaths(fbxctest: "", fbsimctl: "", tempFolder: ""))
        _ = try pool.allocateSimulator()
        XCTAssertThrowsError(_ = try pool.allocateSimulator(), "Expected to throw") { error in
            XCTAssertEqual(error as? BorrowError, BorrowError.noSimulatorsLeft)
        }
    }
    
    func testUsingFromQueue() throws {
        let numberOfThreads = 4
        let pool = SimulatorPool<DefaultSimulatorController>(
            numberOfSimulators: UInt(numberOfThreads),
            testDestination: try TestDestination(deviceType: "", iOSVersion: "11.0"),
            auxiliaryPaths: AuxiliaryPaths(fbxctest: "", fbsimctl: "", tempFolder: ""))
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Int(numberOfThreads)
        
        for _ in 0...999 {
            queue.addOperation {
                do {
                    let simulator = try pool.allocateSimulator()
                    let duration = TimeInterval(Float(arc4random()) / Float(UINT32_MAX) * 0.05)
                    Thread.sleep(forTimeInterval: duration)
                    pool.freeSimulator(simulator)
                } catch {
                    XCTFail("No exception should be thrown")
                }
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
    }
    
    func testAllocatingAndFreeing() throws {
        let pool = SimulatorPool<FakeSimulatorController>(
            numberOfSimulators: 1,
            testDestination: try TestDestination(deviceType: "Fake Device", iOSVersion: "11.3"),
            auxiliaryPaths: AuxiliaryPaths(fbxctest: "", fbsimctl: "", tempFolder: ""),
            automaticCleanupTiumeout: 1)
        let simulatorController = try pool.allocateSimulator()
        pool.freeSimulator(simulatorController)
        
        try SynchronousWaiter.waitWhile(
            pollPeriod: 0.01,
            timeout: SynchronousWaiter.Timeout(description: "Automatic cleanup", value: 2)) {
                simulatorController.didCallDelete == false
        }
        
        XCTAssertTrue(simulatorController.didCallDelete, "Simulator should be automatically cleaned after timeout")
    }
}
