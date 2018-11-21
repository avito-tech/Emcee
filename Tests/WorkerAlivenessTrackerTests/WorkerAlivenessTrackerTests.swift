import Foundation
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class WorkerAlivenessTrackerTests: XCTestCase {
    func test__when_worker_registers__it_is_alive() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__marking_worker_as_alive() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .notRegistered)
        tracker.markWorkerAsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__when_worker_is_silent__tracker_returns_silent() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithImmediateTimeout()
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .notRegistered)
        tracker.markWorkerAsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .silent)
    }
    
    func test__blocked_workers() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.blockWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .blocked)
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
