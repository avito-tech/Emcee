import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import DateProviderTestHelpers
import DistWorkerModels
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import TestHelpers
import TestHistoryTestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class BucketQueueTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture()
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId, capableWorkerId],
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerConfigurations = WorkerConfigurations()
    lazy var workerId: WorkerId = "worker_id"
    let capableWorkerId: WorkerId = "capableWorkerId"
    
    override func setUp() {
        continueAfterFailure = false
        workerAlivenessProvider.didRegisterWorker(workerId: capableWorkerId)
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
    }
    
    func test__whenQueueIsCreated__it_is_depleted() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        XCTAssertTrue(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__if_buckets_enqueued__queue_is_not_depleted() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        try bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])])
        XCTAssertFalse(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__if_buckets_dequeued__queue_is_not_depleted() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        try bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertFalse(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__when_all_results_accepted__queue_is_depleted() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let testingResult = TestingResult(
            testDestination: bucket.testDestination,
            unfilteredResults: []
        )
        assertDoesNotThrow {
            _ = try bucketQueue.accept(
                bucketId: bucket.bucketId,
                testingResult: testingResult,
                workerId: workerId
            )
        }
        
        XCTAssertTrue(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__reponse_dequeuedBucket__when_dequeueing_buckets() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            dateProvider: dateProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider
        )
        try bucketQueue.enqueue(buckets: [bucket])
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        XCTAssertEqual(
            dequeueResult,
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId
                )
            )
        )
    }
    
    func test__reponse_queueIsEmpty__when_dequeueing_bucket_from_empty_queue() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        XCTAssertEqual(dequeueResult, .queueIsEmpty)
    }
    
    func test__reponse_checkAgainLater__when_queue_has_dequeued_buckets() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        if case .checkAgainLater = dequeueResult {
            // pass
        } else {
            XCTFail("Expected dequeueResult == .checkAgainLater, got: \(dequeueResult)")
        }
    }
        
    func test__dequeue_marks_worker_as_alive() {
        workerAlivenessProvider.setWorkerIsSilent(workerId: workerId)
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        _ = bucketQueue.dequeueBucket(
            workerCapabilities: [],
            workerId: workerId
        )
        
        XCTAssertFalse(workerAlivenessProvider.isWorkerSilent(workerId: workerId))
    }
    
    func test__accepting_correct_results() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        try bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let testingResult = TestingResult(
            testDestination: bucket.testDestination,
            unfilteredResults: [TestEntryResult.lost(testEntry: testEntry)]
        )
        assertDoesNotThrow {
            _ = try bucketQueue.accept(
                bucketId: bucket.bucketId,
                testingResult: testingResult,
                workerId: workerId
            )
        }
    }
    
    func test__accepting_result_for_nonexisting_request_id_throws() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        try bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let testingResult = TestingResult(
            testDestination: bucket.testDestination,
            unfilteredResults: [ /* empty - misses testEntry */ ]
        )
        assertThrows {
            try bucketQueue.accept(
                bucketId: "bucket id",
                testingResult: testingResult,
                workerId: workerId
            )
        }
    }
    
    func test__accepting_result_for_nonexisting_worker_id_throws() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        try bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let testingResult = TestingResult(
            testDestination: bucket.testDestination,
            unfilteredResults: [ /* empty - misses testEntry */ ]
        )
        assertThrows {
            try bucketQueue.accept(
                bucketId: bucket.bucketId,
                testingResult: testingResult,
                workerId: "wrong id"
            )
        }
    }
    
    func test__when_worker_is_silent__its_dequeued_buckets_removed() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        workerAlivenessProvider.setWorkerIsSilent(workerId: workerId)
        
        let stuckBuckets = bucketQueue.reenqueueStuckBuckets()
        XCTAssertEqual(
            stuckBuckets,
            [StuckBucket(reason: .workerIsSilent, bucket: bucket, workerId: workerId)]
        )
    }
        
    func test___when_worker_loses_bucket___it_is_removed_as_stuck() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            []
        )
        
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            [StuckBucket(reason: .bucketLost, bucket: bucket, workerId: workerId)]
        )
    }
    
    func test___when_bucket_is_dequeued___aliveness_tracker_is_updated_with_its_id() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: workerId).bucketIdsBeingProcessed,
            [bucket.bucketId]
        )
    }
    
    func test___when_bucket_is_dequeued___stuck_buckets_are_empty() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        try bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            []
        )
    }
    
    func test___removing_enqueued_buckets___affects_state() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)
        
        try bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(methodName: "test1")])])
        try bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(methodName: "test2")])])
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        bucketQueue.removeAllEnqueuedBuckets()
        
        XCTAssertEqual(
            bucketQueue.runningQueueState.enqueuedTests,
            [],
            "After cleaning enqueued buckets, state should indicate there is 0 enqueued buckets left"
        )
    }
    
    func test___enqueuing_same_bucket___reflects_queue_state() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: workerAlivenessProvider)

        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        try bucketQueue.enqueue(buckets: [bucket, bucket])
        
        XCTAssertEqual(
            bucketQueue.runningQueueState.enqueuedTests,
            bucket.testEntries.map { $0.testName } + bucket.testEntries.map { $0.testName },
            "Enqueuing the same bucket multiple times should be reflected in the queue state"
        )
    }
    
    func test___dequeuing_previously_enqueued_same_buckets___one_by_one() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: workerAlivenessProvider
        )
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        try bucketQueue.enqueue(buckets: [bucket, bucket])
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        guard case DequeueResult.dequeuedBucket(let dequeuedBucket) = dequeueResult else {
            return XCTFail("Unexpected dequeue result: \(dequeueResult)")
        }
        
        XCTAssertEqual(
            dequeuedBucket.enqueuedBucket.bucket,
            bucket,
            "Dequeued bucket must match enqueued bucket"
        )
        XCTAssertEqual(
            bucketQueue.runningQueueState.enqueuedTests,
            bucket.testEntries.map { $0.testName },
            "Dequeueing one of the similar buckets should correctly update queue state"
        )
    }
    
    func test___when_worker_capabilities_do_not_meet_bucket_requirements___bucket_is_not_dequeued() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        
        let bucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry()],
            workerCapabilityRequirements: Set([WorkerCapabilityRequirement(capabilityName: "capability", constraint: .equal("1"))])
        )
        
        workerCapabilitiesStorage.set(workerCapabilities: [WorkerCapability(name: "capability", value: "1")], forWorkerId: capableWorkerId)
        
        try bucketQueue.enqueue(buckets: [bucket])
        
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        guard case DequeueResult.checkAgainLater = dequeueResult else {
            failTest("Unexpected dequeue result: \(dequeueResult)")
        }
    }
    
    func test___when_worker_capabilities_meet_bucket_requirements___bucket_is_dequeued() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        
        let bucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry()],
            workerCapabilityRequirements: Set([WorkerCapabilityRequirement(capabilityName: "capability", constraint: .equal("1"))])
        )
        
        workerCapabilitiesStorage.set(workerCapabilities: [WorkerCapability(name: "capability", value: "1")], forWorkerId: workerId)
        
        try bucketQueue.enqueue(buckets: [bucket])
        
        let dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [WorkerCapability(name: "capability", value: "1")], workerId: workerId)
        guard case DequeueResult.dequeuedBucket = dequeueResult else {
            failTest("Unexpected dequeue result: \(dequeueResult)")
        }
    }
    
    func test___when_worker_capabilities_change_and_meet_bucket_requirements___bucket_is_dequeued() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
        
        workerCapabilitiesStorage.set(workerCapabilities: [WorkerCapability(name: "capability", value: "correct")], forWorkerId: capableWorkerId)
        
        let bucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry()],
            workerCapabilityRequirements: Set([WorkerCapabilityRequirement(capabilityName: "capability", constraint: .equal("correct"))])
        )
        
        try bucketQueue.enqueue(buckets: [bucket])
        
        var dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [WorkerCapability(name: "capability", value: "wrong")], workerId: workerId)
        guard case DequeueResult.checkAgainLater = dequeueResult else {
            failTest("Unexpected dequeue result: \(dequeueResult)")
        }
        
        dequeueResult = bucketQueue.dequeueBucket(workerCapabilities: [WorkerCapability(name: "capability", value: "correct")], workerId: workerId)
        guard case DequeueResult.dequeuedBucket = dequeueResult else {
            failTest("Unexpected dequeue result: \(dequeueResult)")
        }
    }
    
    func test___when_bucket_requirements_cannot_be_met_when_enqueuing____error_is_thrown() throws {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: workerAlivenessProvider
        )
        
        let bucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry()],
            workerCapabilityRequirements: Set([WorkerCapabilityRequirement(capabilityName: "unmeetable.capability", constraint: .equal("correct"))])
        )
        
        assertThrows {
            try bucketQueue.enqueue(buckets: [bucket])
        }
    }
    
    func test___test_history_tracker_gets_worker_ids_in_working_condition() throws {
        let testHistoryTracker = FakeTestHistoryTracker()
        testHistoryTracker.validateWorkerIdsInWorkingCondition = { [weak self] workerIds in
            XCTAssertEqual(
                self?.workerAlivenessProvider.workerIdsInWorkingCondition,
                workerIds,
                "Bucket queue should user _complex_ condition to check worker state and use workers that are capable of executing tests, not only alive/enabled/whatever alone."
            )
        }
        workerAlivenessProvider.disableWorker(workerId: workerId)
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            testHistoryTracker: testHistoryTracker,
            workerAlivenessProvider: workerAlivenessProvider
        )
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(workerCapabilities: [], workerId: capableWorkerId)
    }
}
