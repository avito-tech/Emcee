import DistRun
import Foundation
import RESTMethods
import XCTest

final class WorkerAlivenessTrackerTests: XCTestCase {
    func test__when_worker_registers__it_is_alive() {
        let tracker = FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__marking_worker_as_alive() {
        let tracker = FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults()
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .blockedOrNotRegistered)
        tracker.workerIsAlive(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .alive)
    }
    
    func test__blocked_workers() {
        let tracker = FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults()
        tracker.didRegisterWorker(workerId: "worker")
        tracker.didBlockWorker(workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker"), .blockedOrNotRegistered)
    }
}
