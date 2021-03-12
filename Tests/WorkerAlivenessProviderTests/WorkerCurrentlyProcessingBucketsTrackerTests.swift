import Foundation
import QueueModels
import WorkerAlivenessProvider
import XCTest

final class WorkerCurrentlyProcessingBucketsTrackerTests: XCTestCase {
    let tracker = WorkerCurrentlyProcessingBucketsTracker(logger: .noOp)
    let workerId = WorkerId(value: "workerId")
    
    func test___initializing() {
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            []
        )
    }
    
    func test___setting_buckets() {
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid1"]
        )
    }
    
    func test___overriding_buckets() {
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.set(bucketIdsBeingProcessed: ["bucketid2"], byWorkerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid2"]
        )
    }
    
    func test___appending_buckets() {
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.append(bucketId: "bucketid2", workerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            ["bucketid1", "bucketid2"]
        )
    }
    
    func test___resetting_buckets() {
        tracker.set(bucketIdsBeingProcessed: ["bucketid1"], byWorkerId: workerId)
        tracker.resetBucketIdsBeingProcessedBy(workerId: workerId)
        XCTAssertEqual(
            tracker.bucketIdsBeingProcessedBy(workerId: workerId),
            []
        )
    }
}

