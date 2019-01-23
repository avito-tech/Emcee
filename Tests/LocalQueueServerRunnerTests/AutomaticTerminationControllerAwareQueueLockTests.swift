import AutomaticTermination
import LocalQueueServerRunner
import XCTest

final class AutomaticTerminationControllerAwareQueueServerLockTests: XCTestCase {
    func test() {
        let controller = AutomaticTerminationControllerFixture(isTerminationAllowed: false)
        let queueServerLock = AutomaticTerminationControllerAwareQueueServerLock(automaticTerminationController: controller)
        
        XCTAssertTrue(queueServerLock.isDiscoverable)
        
        controller.isTerminationAllowed = true
        XCTAssertFalse(queueServerLock.isDiscoverable)
    }
}

class AutomaticTerminationControllerFixture: AutomaticTerminationController {
    var isTerminationAllowed: Bool

    public init(isTerminationAllowed: Bool) {
        self.isTerminationAllowed = isTerminationAllowed
    }
    
    func indicateActivityFinished() {}
    func add(handler: @escaping AutomaticTerminationControllerHandler) {}
    func startTracking() {}
}
