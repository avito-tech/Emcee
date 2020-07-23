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
}

