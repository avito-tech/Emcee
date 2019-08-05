import AutomaticTermination
import AutomaticTerminationTestHelpers
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
