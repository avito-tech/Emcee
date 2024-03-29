import BucketQueueModels
import Foundation
import QueueModelsTestHelpers
import XCTest

final class EnqueuedBucketTests: XCTestCase {
    let date = Date()
    let bucket = BucketFixtures().bucket()
    
    func test___enqueued_buckets_are_not_equal___when_unique_identifiers_not_equal() {
        XCTAssertNotEqual(
            EnqueuedBucket(bucket: bucket, enqueueTimestamp: date, uniqueIdentifier: UUID().uuidString),
            EnqueuedBucket(bucket: bucket, enqueueTimestamp: date, uniqueIdentifier: UUID().uuidString)
        )
    }
    
    func test___enqueued_buckets_are_equal___when_unique_identifier_is_also_equal() {
        XCTAssertEqual(
            EnqueuedBucket(bucket: bucket, enqueueTimestamp: date, uniqueIdentifier: "uniqueIdentifier"),
            EnqueuedBucket(bucket: bucket, enqueueTimestamp: date, uniqueIdentifier: "uniqueIdentifier")
        )
    }
}

