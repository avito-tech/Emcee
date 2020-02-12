import Foundation
import Models
import SimulatorPool
import SimulatorPoolTestHelpers
import XCTest

final class ActivityAwareSimulatorControllerTests: XCTestCase {
    let fakeSimulatorController = FakeSimulatorController(
        simulator: SimulatorFixture.simulator(),
        simulatorControlTool: .simctl,
        developerDir: .current
    )
    lazy var activityAwareController = ActivityAwareSimulatorController(
        automaticShutdownTimePeriod: 1.0,
        delegate: fakeSimulatorController
    )
    
    func test___when_idle___passes_through() {
        activityAwareController.simulatorBecameIdle()
        
        XCTAssertFalse(fakeSimulatorController.isBusy)
    }
    
    func test___when_busy___passes_through() {
        activityAwareController.simulatorBecameBusy()
        
        XCTAssertTrue(fakeSimulatorController.isBusy)
    }
    
    func test___when_busy___automatic_shutdown_does_not_happen() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has not happened")
        didShutdownAutomatically.isInverted = true
        
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didShutdownAutomatically], timeout: 5)
    }
    
    func test___when_idle___automatic_shutdown_happens() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has happened")
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        wait(for: [didShutdownAutomatically], timeout: 15)
    }
    
    func test___when_idle_then_busy___automatic_shutdown_does_not_happen() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has not happened")
        didShutdownAutomatically.isInverted = true
        
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didShutdownAutomatically], timeout: 5)
    }
}
