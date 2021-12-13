import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import WorkerAlivenessModels
import WorkerAlivenessProvider
import XCTest

final class WorkerAlivenessProviderTests: XCTestCase {
    func test__when_worker_registers__it_is_alive() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertFalse(tracker.alivenessForWorker(workerId: "worker").silent)
    }
    
    func test__when_worker_registers__it_has_no_buckets_being_processed() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        XCTAssertFalse(tracker.alivenessForWorker(workerId: "worker").registered)
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertFalse(tracker.alivenessForWorker(workerId: "worker").silent)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test__marking_worker_as_alive___registers_buckets_being_processing() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        tracker.set(bucketIdsBeingProcessed: ["bucketid"], workerId: "worker")
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, ["bucketid"])
    }
    
    func test__when_worker_is_silent__tracker_returns_silent() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        XCTAssertFalse(tracker.alivenessForWorker(workerId: "worker").registered)
        tracker.didRegisterWorker(workerId: "worker")
        tracker.setWorkerIsSilent(workerId: "worker")
        XCTAssertTrue(tracker.alivenessForWorker(workerId: "worker").silent)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, [])
    }
    
    func test___when_worker_is_silent___tracker_includes_buckets_being_processed() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        tracker.set(bucketIdsBeingProcessed: ["bucketid"], workerId: "worker")
        tracker.setWorkerIsSilent(workerId: "worker")
        XCTAssertTrue(tracker.alivenessForWorker(workerId: "worker").silent)
        XCTAssertEqual(tracker.alivenessForWorker(workerId: "worker").bucketIdsBeingProcessed, ["bucketid"])
    }
    
    func test__availability_of_workers() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        XCTAssertTrue(tracker.hasAnyAliveWorker)
    }
    
    func test___aliveness_for_not_registered_workers() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        XCTAssertEqual(
            tracker.workerAliveness,
            [:]
        )
    }
    
    func test___disabling_worker___keeps_processing_buckets() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        tracker.didDequeueBucket(bucketId: "bucketId", workerId: "worker")
        tracker.disableWorker(workerId: "worker")
        
        XCTAssertEqual(
            tracker.workerAliveness,
            [
                WorkerId(value: "worker"): WorkerAliveness(
                    registered: true,
                    bucketIdsBeingProcessed: ["bucketId"],
                    disabled: true,
                    silent: false,
                    workerUtilizationPermission: .allowedToUtilize
                )
            ]
        )
    }
    
    func test___enabling_worker___keeps_processing_buckets() {
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        tracker.didRegisterWorker(workerId: "worker")
        tracker.didDequeueBucket(bucketId: "bucketId", workerId: "worker")
        tracker.disableWorker(workerId: "worker")
        tracker.enableWorker(workerId: "worker")
        
        XCTAssertEqual(
            tracker.workerAliveness,
            [
                WorkerId(value: "worker"): WorkerAliveness(
                    registered: true,
                    bucketIdsBeingProcessed: ["bucketId"],
                    disabled: false,
                    silent: false,
                    workerUtilizationPermission: .allowedToUtilize
                )
            ]
        )
    }
    
    func test___provides_worker_utilization_permission() {
        let workerPermissionProvider = FakeWorkerPermissionProvider()
        workerPermissionProvider.permission = .notAllowedToUtilize
        
        let tracker = WorkerAlivenessProviderImpl(
            logger: .noOp,
            workerPermissionProvider: workerPermissionProvider
        )
        XCTAssertEqual(
            tracker.alivenessForWorker(workerId: "worker"),
            WorkerAliveness(
                registered: false,
                bucketIdsBeingProcessed: [],
                disabled: false,
                silent: false,
                workerUtilizationPermission: .notAllowedToUtilize
            )
        )
    }
}
