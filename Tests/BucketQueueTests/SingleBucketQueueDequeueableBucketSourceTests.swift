import BucketQueue
import BucketQueueModels
import Foundation
import TestHistoryTracker
import TestHistoryTestHelpers
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class SingleBucketQueueDequeueableBucketSourceTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var testHistoryTracker = FakeTestHistoryTracker()
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        logger: .noOp,
        workerPermissionProvider: workerPermissionProvider
    )
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    lazy var workerPermissionProvider = FakeWorkerPermissionProvider()
    lazy var workerId = WorkerId("workerId")
    
    lazy var source = SingleBucketQueueDequeueableBucketSource(
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        testHistoryTracker: testHistoryTracker,
        workerAlivenessProvider: workerAlivenessProvider,
        workerCapabilitiesStorage: workerCapabilitiesStorage
    )
    
    func test___dequeue_marks_alive() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.setWorkerIsSilent(workerId: workerId)
        
        _ = source.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertFalse(workerAlivenessProvider.isWorkerSilent(workerId: workerId))
    }
    
    func test___dequeue_updates_worker_capabilities() {
        workerCapabilitiesStorage.set(workerCapabilities: [], forWorkerId: workerId)
        
        let capability = WorkerCapability(name: "name", value: "value")
        
        _ = source.dequeueBucket(workerCapabilities: [capability], workerId: workerId)
        
        XCTAssertEqual(
            workerCapabilitiesStorage.workerCapabilities(forWorkerId: workerId),
            [capability]
        )
    }
    
    func test___returns_nil___when_history_tracker_returns_nil() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        testHistoryTracker.enqueuedPayloadToDequeueProvider = { _, _, workerId in
            return nil
        }
        
        XCTAssertNil(
            source.dequeueBucket(workerCapabilities: [], workerId: workerId)
        )
    }
    
    func test___returns_dequeued_bucket___when_worker_satisifies_bucket_requirements() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let runIosTestsPayload = BucketFixtures.createRunIosTestsPayload()
        
        let bucket = BucketFixtures.createBucket(
            bucketPayload: .runIosTests(runIosTestsPayload),
            workerCapabilityRequirements: [
                WorkerCapabilityRequirement(capabilityName: "name", constraint: .present)
            ]
        )
        
        let enqueuedBucket = EnqueuedBucket(
            bucket: bucket,
            enqueueTimestamp: Date(),
            uniqueIdentifier: "id"
        )
        
        bucketQueueHolder.insert(enqueuedBuckets: [enqueuedBucket], position: 0)
        
        testHistoryTracker.enqueuedPayloadToDequeueProvider = { _, _, _ in
            EnqueuedRunIosTestsPayload(
                bucketId: bucket.bucketId,
                testDestination: runIosTestsPayload.testDestination,
                testEntries: runIosTestsPayload.testEntries,
                numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries
            )
        }
        
        let dequeuedBucket = source.dequeueBucket(
            workerCapabilities: [
                WorkerCapability(name: "name", value: "value")
            ],
            workerId: workerId
        )
        XCTAssertEqual(
            dequeuedBucket,
            DequeuedBucket(enqueuedBucket: enqueuedBucket, workerId: workerId)
        )
    }
    
    func test___returns_nil___when_worker_does_not_satisfy_bucket_requirements() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let runIosTestsPayload = BucketFixtures.createRunIosTestsPayload()
        
        let bucket = BucketFixtures.createBucket(
            bucketPayload: .runIosTests(runIosTestsPayload),
            workerCapabilityRequirements: [
                WorkerCapabilityRequirement(capabilityName: "name", constraint: .present)
            ]
        )
        
        let payload = EnqueuedRunIosTestsPayload(
            bucketId: bucket.bucketId,
            testDestination: runIosTestsPayload.testDestination,
            testEntries: runIosTestsPayload.testEntries,
            numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries
        )

        testHistoryTracker.enqueuedPayloadToDequeueProvider = { _, _, _ in payload }
        
        let dequeuedBucket = source.dequeueBucket(
            workerCapabilities: [],
            workerId: workerId
        )
        XCTAssertNil(
            dequeuedBucket
        )
    }
    
    func test___queries_test_history_tracker_when_workers_in_working_condition() {
        let checked1 = XCTestExpectation()
        
        testHistoryTracker.enqueuedPayloadToDequeueProvider = { _, _, workerIds in
            XCTAssertTrue(workerIds.isEmpty)
            checked1.fulfill()
            return nil
        }
        _ = source.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let checked2 = XCTestExpectation()
        
        testHistoryTracker.enqueuedPayloadToDequeueProvider = { [workerId] _, _, workerIds in
            XCTAssertEqual(workerIds, [workerId])
            checked2.fulfill()
            return nil
        }
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        _ = source.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        wait(for: [checked1, checked2], timeout: 5)
    }
}

