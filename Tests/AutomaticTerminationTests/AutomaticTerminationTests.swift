@testable import AutomaticTermination
import XCTest

final class PolicyTests: XCTestCase {
    
    let mutableDateProvider = MutableDateProvider()
    
    func test___getting_time_period_from_policy() {
        XCTAssertEqual(AutomaticTerminationPolicy.after(timeInterval: 333).period, 333.0, accuracy: 0.1)
        XCTAssertEqual(AutomaticTerminationPolicy.afterBeingIdle(period: 555).period, 555.0, accuracy: 0.1)
        XCTAssertEqual(AutomaticTerminationPolicy.stayAlive.period, .infinity)
    }
    
    func test___stay_alive_policy___always_disallows_termination() {
        let controller = StayAliveTerminationController()
        XCTAssertFalse(controller.isTerminationAllowed)
    }
    
    func test___after_time_interval___allows_termination_after_time_interval() {
        let inFuture = AfterFixedPeriodOfTimeTerminationController(
            dateProvider: mutableDateProvider,
            fireAt: mutableDateProvider.date.addingTimeInterval(100.0)
        )
        XCTAssertFalse(inFuture.isTerminationAllowed)
        
        let inPast = AfterFixedPeriodOfTimeTerminationController(
            dateProvider: mutableDateProvider,
            fireAt: mutableDateProvider.date.addingTimeInterval(-100.0)
        )
        XCTAssertTrue(inPast.isTerminationAllowed)
    }
    
    func test___after_period_of_inactivity___allows_termination_after_time_interval() {
        let controller = AfterPeriodOfInactivityTerminationController(
            dateProvider: mutableDateProvider,
            inactivityInterval: 5.0
        )
        mutableDateProvider.add(timeInterval: 4.9)
        XCTAssertFalse(controller.isTerminationAllowed)
        mutableDateProvider.add(timeInterval: 0.2)
        XCTAssertTrue(controller.isTerminationAllowed)
    }
    
    func test___after_period_of_inactivity___activity_does_not_change_termination_allowance() {
        let controller = AfterPeriodOfInactivityTerminationController(
            dateProvider: mutableDateProvider,
            inactivityInterval: 5.0
        )
        mutableDateProvider.add(timeInterval: 5.1)
        XCTAssertTrue(controller.isTerminationAllowed)
        controller.indicateActivityFinished()
        XCTAssertTrue(controller.isTerminationAllowed)
    }
    
    func test___after_period_of_inactivity___activity_prolongs_termination_disallowance() {
        let controller = AfterPeriodOfInactivityTerminationController(
            dateProvider: mutableDateProvider,
            inactivityInterval: 5.0
        )
        XCTAssertFalse(controller.isTerminationAllowed)
        
        mutableDateProvider.add(timeInterval: 4.9)
        controller.indicateActivityFinished()
        XCTAssertFalse(controller.isTerminationAllowed)
        
        mutableDateProvider.add(timeInterval: 5.0)
        XCTAssertFalse(controller.isTerminationAllowed)
        
        mutableDateProvider.add(timeInterval: 0.01)
        XCTAssertTrue(controller.isTerminationAllowed)
    }
    
    func test___after_period_of_inactivity___handler_fires() {
        let controller = AfterPeriodOfInactivityTerminationController(
            dateProvider: mutableDateProvider,
            inactivityInterval: 100.0
        )
        controller.startTracking()
        
        let handlerDidFireExpectation = expectation(description: "handler did fire on automatic termination")
        controller.add {
            handlerDidFireExpectation.fulfill()
        }
        mutableDateProvider.add(timeInterval: 101)
        
        wait(for: [handlerDidFireExpectation], timeout: 5.0)
    }
    
    func test___after_time_interval___handler_fires() {
        let controller = AfterFixedPeriodOfTimeTerminationController(
            dateProvider: mutableDateProvider,
            fireAt: mutableDateProvider.currentDate().addingTimeInterval(100)
        )
        controller.startTracking()
        
        let handlerDidFireExpectation = expectation(description: "handler did fire on automatic termination")
        controller.add {
            handlerDidFireExpectation.fulfill()
        }
        mutableDateProvider.add(timeInterval: 101)
        
        wait(for: [handlerDidFireExpectation], timeout: 5.0)
    }
}

class MutableDateProvider: DateProvider {
    public init(date: Date = Date(timeIntervalSinceReferenceDate: 0.0)) {
        self.date = date
    }
    
    var date: Date
    
    func add(timeInterval: TimeInterval) {
        date = date.addingTimeInterval(timeInterval)
    }
    
    func currentDate() -> Date {
        return date
    }
}
