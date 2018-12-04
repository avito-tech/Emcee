import Foundation
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class WorkerAlivenessTrackerTests: XCTestCase {
    func test__when_worker_registers__it_is_alive() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .alive)
    }
    
    func test__when_worker_registers__it_has_no_buckets_being_processed() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test__marking_worker_as_alive() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .notRegistered)
        tracker.markWorkerAsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .alive)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test__marking_worker_as_alive___registers_buckets_being_processing() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.set(bucketIdsBeingProcessed: ["bucketid"], workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, ["bucketid"])
    }
    
    func test__when_worker_is_silent__tracker_returns_silent() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithImmediateTimeout()
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .notRegistered)
        tracker.markWorkerAsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .silent)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test___when_worker_is_silent___tracker_includes_buckets_being_processed() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithImmediateTimeout()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.set(bucketIdsBeingProcessed: ["bucketid"], workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .silent)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, ["bucketid"])
    }
    
    func test__blocked_workers() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.blockWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .blocked)
    }
    
    func test___if_worker_blocked___aliveness_does_not_include_buckets_being_processed() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.set(bucketIdsBeingProcessed: ["bucketid"], workerId: "worker")
        tracker.blockWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test__availability_of_workers() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertTrue(tracker.hasAnyAliveWorker)
    }
    
    func test__availability_of_workers__after_blocking_last_worker() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.blockWorker(workerId: "worker")
        XCTAssertFalse(tracker.hasAnyAliveWorker)
    }
}
