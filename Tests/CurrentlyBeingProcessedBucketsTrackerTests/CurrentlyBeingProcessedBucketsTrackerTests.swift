import CurrentlyBeingProcessedBucketsTracker
import Foundation
import XCTest

final class CurrentlyBeingProcessedBucketsTrackerTests: XCTestCase {
    func test___fetch_registers_bucket_id() {
        let tracker = CurrentlyBeingProcessedBucketsTracker()
        tracker.didFetch(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, ["bucket1"])
    }
    
    func test___result_drops_bucket_id() {
        let tracker = CurrentlyBeingProcessedBucketsTracker()
        tracker.didFetch(bucketId: "bucket1")
        tracker.didSendResults(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, [])
    }
    
    func test___double_fetch_of_same_bucket_keeps_bucket_id___after_first_result() {
        let tracker = CurrentlyBeingProcessedBucketsTracker()
        tracker.didFetch(bucketId: "bucket1")
        tracker.didFetch(bucketId: "bucket1")
        tracker.didSendResults(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, ["bucket1"])
    }
}
