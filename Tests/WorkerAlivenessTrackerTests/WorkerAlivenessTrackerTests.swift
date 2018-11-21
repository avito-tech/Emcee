import Foundation
import WorkerAlivenessTracker
import XCTest

final class WorkerAlivenessTrackerTests: XCTestCase {
    func test__when_worker_registers__it_is_alive() {
        let tracker = WorkerAlivenessTracker(reportAliveInterval: .infinity)
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__marking_worker_as_alive() {
        let tracker = WorkerAlivenessTracker(reportAliveInterval: .infinity)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .unknown)
        tracker.workerIsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__when_worker_is_silent__tracker_returns_silent() {
        let tracker = WorkerAlivenessTracker(reportAliveInterval: 0.0, additionalTimeToPerformWorkerIsAliveReport: 0.0)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .unknown)
        tracker.workerIsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .silent)
    }
    
    func test__blocked_workers() {
        let tracker = WorkerAlivenessTracker(reportAliveInterval: .infinity)
        tracker.didRegisterWorker(workerId: "worker")
        tracker.didBlockWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .unknown)
    }
}
