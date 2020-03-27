import BalancingBucketQueue
import Foundation
import XCTest

final class JobGroupTests: XCTestCase {
    func test___creation_time_order() {
        XCTAssertEqual(
            createJobGroup(creationTime: Date(timeIntervalSince1970: 100)).executionOrder(
                relativeTo: createJobGroup(creationTime: Date(timeIntervalSince1970: 200))
            ),
            .before
        )
    }
    
    func test___priority_order() {
        XCTAssertEqual(
            createJobGroup(priority: .highest).executionOrder(
                relativeTo: createJobGroup(priority: .lowest)
            ),
            .before
        )
    }
    
    func test___creation_time_and_priority_order___priority_has_order_over_creation_time() {
        XCTAssertEqual(
            createJobGroup(creationTime: Date(timeIntervalSince1970: 100), priority: .highest).executionOrder(
            relativeTo: createJobGroup(creationTime: Date(timeIntervalSince1970: 500), priority: .lowest)
            ),
            .before
        )
    }
}
