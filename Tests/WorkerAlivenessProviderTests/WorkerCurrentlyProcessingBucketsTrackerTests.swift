import Foundation
import QueueModels
import WorkerAlivenessProvider
import XCTest

final class WorkerCurrentlyProcessingBucketsTrackerTests: XCTestCase {
    let workerId = WorkerId(value: "workerId")
    
    func test___initializing() {
        let tracker = WorkerCurrentlyProcessingBucketsTracker()
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            []
        )
    }
    
    func test___setting_buckets() {
        let tracker = WorkerCurrentlyProcessingBucketsTracker()
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid1"]
        )
    }
    
    func test___overriding_buckets() {
        let tracker = WorkerCurrentlyProcessingBucketsTracker()
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.set(bucketIdsBeingProcessed: ["bucketid2"], byWorkerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid2"]
        )
    }
    
    func test___appending_buckets() {
        let tracker = WorkerCurrentlyProcessingBucketsTracker()
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.append(bucketId: "bucketid2", workerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid1", "bucketid2"]
        )
    }
    
    func test___resetting_buckets() {
        let tracker = WorkerCurrentlyProcessingBucketsTracker()
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.resetBucketIdsBeingProcessedBy(workerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            []
        )
    }
}

