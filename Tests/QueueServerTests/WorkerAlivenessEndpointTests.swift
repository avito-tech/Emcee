import Foundation
import Models
import QueueServer
import RESTMethods
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class WorkerAlivenessEndpointTests: XCTestCase {
    let expectedRequestSignature = RequestSignature(value: "expectedRequestSignature")

    func test___handling_requests() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let endpoint = WorkerAlivenessEndpoint(
            alivenessTracker: tracker,
            expectedRequestSignature: expectedRequestSignature
        )
        XCTAssertNoThrow(
            try endpoint.handle(
                verifiedRequest: ReportAliveRequest(
                    workerId: "worker",
                    bucketIdsBeingProcessed: [],
                    requestSignature: expectedRequestSignature
                )
            )
        )
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .alive)
    }
    
    func test___worker_is_silent_when_it_does_not_report_within_allowed_timeframe() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithImmediateTimeout()
        let endpoint = WorkerAlivenessEndpoint(
            alivenessTracker: tracker,
            expectedRequestSignature: expectedRequestSignature
        )
        XCTAssertNoThrow(
            try endpoint.handle(
                verifiedRequest: ReportAliveRequest(
                    workerId: "worker",
                    bucketIdsBeingProcessed: [],
                    requestSignature: expectedRequestSignature
                )
            )
        )
        Thread.sleep(forTimeInterval: .leastNonzeroMagnitude)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").status, .silent)
    }
    
    func test___handling_requests___sets_buckets_being_processed() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let endpoint = WorkerAlivenessEndpoint(
            alivenessTracker: tracker,
            expectedRequestSignature: expectedRequestSignature
        )
        XCTAssertNoThrow(
            try endpoint.handle(
                verifiedRequest: ReportAliveRequest(
                    workerId: "worker",
                    bucketIdsBeingProcessed: ["bucketid"],
                    requestSignature: expectedRequestSignature
                )
            )
        )
        XCTAssertEqual(
            tracker.alivenessForWorker(workerId: "worker"),
            WorkerAliveness(status: .alive, bucketIdsBeingProcessed: ["bucketid"])
        )
    }

    func test___throws___when_request_signature_mismatches() {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        let endpoint = WorkerAlivenessEndpoint(
            alivenessTracker: tracker,
            expectedRequestSignature: expectedRequestSignature
        )
        XCTAssertThrowsError(
            try endpoint.handle(
                decodedRequest: ReportAliveRequest(
                    workerId: "worker",
                    bucketIdsBeingProcessed: ["bucketid"],
                    requestSignature: RequestSignature(value: UUID().uuidString)
                )
            ),
            "When request signature mismatches, bucket provider endpoind should throw"
        )
    }
}
