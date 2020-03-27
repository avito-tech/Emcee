import BalancingBucketQueue
import Foundation
import XCTest

final class JobTests: XCTestCase {
    func test___creation_time_preeminance() {
        XCTAssertEqual(
            createJob(creationTime: Date(timeIntervalSince1970: 100)).executionOrder(
                relativeTo: createJob(creationTime: Date(timeIntervalSince1970: 200))
            ),
            .before
        )
    }
    
    func test___priority_preeminance() {
        XCTAssertEqual(
            createJob(priority: .highest).executionOrder(
                relativeTo: createJob(priority: .lowest)
            ),
            .before
        )
    }
    
    func test___creation_time_and_priority_preeminance___priority_has_preeminance_over_creation_time() {
        XCTAssertEqual(
            createJob(creationTime: Date(timeIntervalSince1970: 100), priority: .highest).executionOrder(
                relativeTo: createJob(creationTime: Date(timeIntervalSince1970: 500), priority: .lowest)
            ),
            .before
        )
    }
}
