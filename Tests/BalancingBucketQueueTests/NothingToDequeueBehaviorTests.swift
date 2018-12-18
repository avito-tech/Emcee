import BalancingBucketQueue
import Foundation
import XCTest

final class NothingToDequeueBehaviorTests: XCTestCase {
    func test___check_again_dequeue_behavior() {
        let behavior = NothingToDequeueBehaviorCheckLater(checkAfter: 42)
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: []),
            .checkAgainLater(checkAfter: 42)
        )
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [.checkAgainLater(checkAfter: 30)]),
            .checkAgainLater(checkAfter: 42)
        )
    }
    
    func test___wait_for_queues_to_deplete_dequeue_behavior() {
        let behavior = NothingToDequeueBehaviorWaitForAllQueuesToDeplete(checkAfter: 42)
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [.queueIsEmpty, .checkAgainLater(checkAfter: .infinity)]),
            .checkAgainLater(checkAfter: 42)
        )
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[.queueIsEmpty, .queueIsEmpty]),
            .queueIsEmpty
        )
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[.workerBlocked, .workerBlocked]),
            .workerBlocked
        )
        XCTAssertEqual(
            behavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[.checkAgainLater(checkAfter: .infinity), .checkAgainLater(checkAfter: 0)]),
            .checkAgainLater(checkAfter: 42)
        )
    }
}

