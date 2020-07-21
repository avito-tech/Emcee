import DistWorker
import Foundation
import QueueModels
import XCTest

final class CurrentlyBeingProcessedBucketsTrackerTests: XCTestCase {
    func test___fetch_registers_bucket_id() {
        let tracker = DefaultCurrentlyBeingProcessedBucketsTracker()
        tracker.willProcess(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, ["bucket1"])
    }
    
    func test___result_drops_bucket_id() {
        let tracker = DefaultCurrentlyBeingProcessedBucketsTracker()
        tracker.willProcess(bucketId: "bucket1")
        tracker.didProcess(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, [])
    }
    
    func test___double_fetch_of_same_bucket_keeps_bucket_id___after_first_result() {
        let tracker = DefaultCurrentlyBeingProcessedBucketsTracker()
        tracker.willProcess(bucketId: "bucket1")
        tracker.willProcess(bucketId: "bucket1")
        tracker.didProcess(bucketId: "bucket1")
        XCTAssertEqual(tracker.bucketIdsBeingProcessed, ["bucket1"])
    }
    
    func test___perform_locks_from_modification() {
        let impactQueue = DispatchQueue(label: "impact_queue", attributes: .concurrent)
        
        let tracker = DefaultCurrentlyBeingProcessedBucketsTracker()
        
        var orderCheck = 0
        
        impactQueue.asyncAfter(deadline: .now() + .seconds(1)) {
            tracker.willProcess(bucketId: "bucket")
            orderCheck *= 5
            XCTAssertEqual(
                tracker.bucketIdsBeingProcessed,
                [BucketId("bucket")]
            )
        }
        
        tracker.perform { tracker -> () in
            orderCheck += 2
            Thread.sleep(forTimeInterval: 5)
            
            XCTAssertEqual(
                tracker.bucketIdsBeingProcessed,
                [],
                "perform() call should block from modification: willProcess() should be processed only after perform() finishes"
            )
        }
        
        impactQueue.sync(flags: .barrier) {
            XCTAssertEqual(
                orderCheck,
                10,
                "Incorrect order of execution: willProcess() call must be blocked by perform()"
            )
        }
    }
}
