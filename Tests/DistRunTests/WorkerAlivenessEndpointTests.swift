import DistRun
import Foundation
import RESTMethods
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class WorkerAlivenessEndpointTests: XCTestCase {
    func test___handling_requests() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let endpoint = WorkerAlivenessEndpoint(alivenessTracker: tracker)
        XCTAssertNoThrow(try endpoint.handle(decodedRequest: ReportAliveRequest(workerId: "worker", bucketIdsBeingProcessed: [])))
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .alive)
    }
    
    func test___worker_is_silent_when_it_does_not_report_within_allowed_timeframe() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithImmediateTimeout()
        let endpoint = WorkerAlivenessEndpoint(alivenessTracker: tracker)
        XCTAssertNoThrow(try endpoint.handle(decodedRequest: ReportAliveRequest(workerId: "worker", bucketIdsBeingProcessed: [])))
        Thread.sleep(forTimeInterval: .leastNonzeroMagnitude)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .silent)
    }
    
    func test___handling_requests___sets_buckets_being_processed() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let endpoint = WorkerAlivenessEndpoint(alivenessTracker: tracker)
        XCTAssertNoThrow(
            try endpoint.handle(
                decodedRequest: ReportAliveRequest(
                    workerId: "worker",
                    bucketIdsBeingProcessed: ["bucketid"]
                )
            )
        )
        XCTAssertEqual(
            tracker.alivenessForWorker(workerId: "worker"),
            WorkerAliveness(status: .alive, bucketIdsBeingProcessed: ["bucketid"])
        )
    }
}
