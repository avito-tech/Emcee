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
        automaticDeleteTimePeriod: 1.0,
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
    
    func test___when_busy___automatic_delete_does_not_happen() {
        let didDeleteAutomatically = expectation(description: "Automatic deletion has not happened")
        didDeleteAutomatically.isInverted = true
        
        fakeSimulatorController.onDelete = didDeleteAutomatically.fulfill
        
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didDeleteAutomatically], timeout: 5)
    }
    
    func test___when_idle___automatic_shutdown_happens() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has happened")
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        wait(for: [didShutdownAutomatically], timeout: 15)
    }
    
    func test___when_idle___automatic_delete_happens() {
        let didDeleteAutomatically = expectation(description: "Automatic deletion has happened")
        fakeSimulatorController.onDelete = didDeleteAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        wait(for: [didDeleteAutomatically], timeout: 15)
    }
    
    func test___when_idle___automatic_delete_happens_after_automatic_shutdown() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has happened")
        let didDeleteAutomatically = expectation(description: "Automatic deletion has happened")
        
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        fakeSimulatorController.onDelete = didDeleteAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        
        wait(for: [didShutdownAutomatically], timeout: 15)
        XCTAssertFalse(
            fakeSimulatorController.didCallDelete,
            "Delete should be called after shutdown has happened, plus timeinterval, not immediately"
        )
        wait(for: [didDeleteAutomatically], timeout: 15)
    }
    
    func test___when_automatic_shudown_happens___and_simulator_becomes_busy___automatic_deletion_does_not_happen() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has happened")
        let didDeleteAutomatically = expectation(description: "Automatic deletion has not happened")
        didDeleteAutomatically.isInverted = true
        
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        fakeSimulatorController.onDelete = didDeleteAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        
        wait(for: [didShutdownAutomatically], timeout: 15)
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didDeleteAutomatically], timeout: 5)
    }
    
    func test___when_shutdown___automatic_delete_happens() {
        let didDeleteAutomatically = expectation(description: "Automatic deletion has happened")
        fakeSimulatorController.onDelete = didDeleteAutomatically.fulfill
        
        assertDoesNotThrow { try activityAwareController.deleteSimulator() }
        
        wait(for: [didDeleteAutomatically], timeout: 15)
    }
    
    func test___when_idle_then_busy___automatic_shutdown_does_not_happen() {
        let didShutdownAutomatically = expectation(description: "Automatic shutdown has not happened")
        didShutdownAutomatically.isInverted = true
        
        fakeSimulatorController.onShutdown = didShutdownAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didShutdownAutomatically], timeout: 5)
    }
    
    func test___when_idle_then_busy___automatic_deletion_does_not_happen() {
        let didDeleteAutomatically = expectation(description: "Automatic deletion has not happened")
        didDeleteAutomatically.isInverted = true
        
        fakeSimulatorController.onShutdown = didDeleteAutomatically.fulfill
        
        activityAwareController.simulatorBecameIdle()
        activityAwareController.simulatorBecameBusy()
        
        wait(for: [didDeleteAutomatically], timeout: 5)
    }
}
