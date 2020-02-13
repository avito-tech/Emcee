import BucketQueue
import BucketQueueTestHelpers
import DateProviderTestHelpers
import DistWorkerModels
import Foundation
import Models
import ModelsTestHelpers
import QueueModels
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class BucketQueueTests: XCTestCase {
    let workerConfigurations = WorkerConfigurations()
    
    let workerId: WorkerId = "worker_id"
    let requestId: RequestId = "request_id"
    let alivenessTrackerWithImmediateTimeout = WorkerAlivenessProviderFixtures.alivenessTrackerWithImmediateTimeout()
    let alivenessTrackerWithAlwaysAliveResults = WorkerAlivenessProviderFixtures.alivenessTrackerWithAlwaysAliveResults()
    let mutableAlivenessProvider = MutableWorkerAlivenessProvider()
    let dateProvider = DateProviderFixture()
    let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    
    override func setUp() {
        continueAfterFailure = false
        
        alivenessTrackerWithImmediateTimeout.didRegisterWorker(workerId: workerId)
        alivenessTrackerWithAlwaysAliveResults.didRegisterWorker(workerId: workerId)
        mutableAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
    }
    
    func test__whenQueueIsCreated__it_is_depleted() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithImmediateTimeout)
        XCTAssertTrue(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__if_buckets_enqueued__queue_is_not_depleted() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithImmediateTimeout)
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [])])
        XCTAssertFalse(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__if_buckets_dequeued__queue_is_not_depleted() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithImmediateTimeout)
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [])])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertFalse(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__when_all_results_accepted__queue_is_depleted() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [])
        XCTAssertNoThrow(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId))
        
        XCTAssertTrue(bucketQueue.runningQueueState.isDepleted)
    }
    
    func test__reponse_dequeuedBucket__when_dequeueing_buckets() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            dateProvider: dateProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults
        )
        bucketQueue.enqueue(buckets: [bucket])
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(
            dequeueResult,
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId,
                    requestId: requestId
                )
            )
        )
    }
    
    func test__reponse_queueIsEmpty__when_dequeueing_bucket_from_empty_queue() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(dequeueResult, .queueIsEmpty)
    }
    
    func test__reponse_checkAgainLater__when_queue_has_dequeued_buckets() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let dequeueResult = bucketQueue.dequeueBucket(requestId: "some other request", workerId: workerId)
        
        if case .checkAgainLater = dequeueResult {
            // pass
        } else {
            XCTFail("Expected dequeueResult == .checkAgainLater, got: \(dequeueResult)")
        }
    }
    
    func test__reponse_workerBlocked__when_worker_is_blocked() {
        alivenessTrackerWithAlwaysAliveResults.blockWorker(workerId: workerId)
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        bucketQueue.enqueue(buckets: [bucket])
        
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(dequeueResult, .workerIsBlocked)
    }
    
    func test__reponse_workerIsNotAlive__when_worker_is_not_alive() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        let dequeueResult = bucketQueue.dequeueBucket(
            requestId: requestId,
            workerId: WorkerId(value: UUID().uuidString)
        )
        XCTAssertEqual(dequeueResult, .workerIsNotAlive)
    }
    
    func test__dequeueing_previously_dequeued_buckets() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            dateProvider: dateProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults
        )
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(
            dequeueResult,
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId,
                    requestId: requestId
                )
            )
        )
    }
    
    func test__accepting_correct_results() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [TestEntryResult.lost(testEntry: testEntry)])
        XCTAssertNoThrow(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId))
    }
    
    func test__accepting_result_for_nonexisting_request_id_throws() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [ /* empty - misses testEntry */ ])
        XCTAssertThrowsError(try bucketQueue.accept(testingResult: testingResult, requestId: "wrong id", workerId: workerId))
    }
    
    func test__accepting_result_for_nonexisting_worker_id_throws() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithImmediateTimeout)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class", methodName: "test")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [ /* empty - misses testEntry */ ])
        XCTAssertThrowsError(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: "wrong id"))
    }
    
    func test__when_worker_is_silent__its_dequeued_buckets_removed() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        let silentSince = Date()
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: mutableAlivenessProvider)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        mutableAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(
            status: .silent(lastAlivenessResponseTimestamp: silentSince),
            bucketIdsBeingProcessed: []
        )
        
        let stuckBuckets = bucketQueue.reenqueueStuckBuckets()
        XCTAssertEqual(
            stuckBuckets,
            [StuckBucket(reason: .workerIsSilent(since: silentSince), bucket: bucket, workerId: workerId, requestId: requestId)]
        )
    }
    
    func test__when_worker_is_blocked__its_dequeued_buckets_removed() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        alivenessTrackerWithAlwaysAliveResults.blockWorker(workerId: workerId)
        let stuckBuckets = bucketQueue.reenqueueStuckBuckets()
        XCTAssertEqual(
            stuckBuckets,
            [StuckBucket(reason: .workerIsBlocked, bucket: bucket, workerId: workerId, requestId: requestId)]
        )
    }
    
    func test___when_worker_loses_bucket___it_is_removed_as_stuck() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            []
        )
        
        alivenessTrackerWithAlwaysAliveResults.set(bucketIdsBeingProcessed: [], workerId: workerId)
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            [StuckBucket(reason: .bucketLost, bucket: bucket, workerId: workerId, requestId: requestId)]
        )
    }
    
    func test___when_bucket_is_dequeued___aliveness_tracker_is_updated_with_its_id() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(
            alivenessTrackerWithAlwaysAliveResults.alivenessForWorker(workerId: workerId).bucketIdsBeingProcessed,
            [bucket.bucketId]
        )
    }
    
    func test___when_bucket_is_dequeued___stuck_buckets_are_empty() {
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(
            bucketQueue.reenqueueStuckBuckets(),
            []
        )
    }
    
    func test___removing_enqueued_buckets___affects_state() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)
        
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(methodName: "test1")])])
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(methodName: "test2")])])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        bucketQueue.removeAllEnqueuedBuckets()
        
        XCTAssertEqual(
            bucketQueue.runningQueueState,
            RunningQueueState(enqueuedBucketCount: 0, dequeuedBucketCount: 1),
            "After cleaning enqueued buckets, state should indicate there is 0 enqueued buckets left"
        )
    }
    
    func test___enqueuing_same_bucket___reflects_queue_state() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults)

        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        bucketQueue.enqueue(buckets: [bucket, bucket])
        
        XCTAssertEqual(
            bucketQueue.runningQueueState.enqueuedBucketCount,
            2,
            "Enqueuing the same bucket multiple times should be reflected in the queue state"
        )
    }
    
    func test___dequeuing_previously_enqueued_same_buckets___one_by_one() {
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            workerAlivenessProvider: alivenessTrackerWithAlwaysAliveResults
        )
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        
        bucketQueue.enqueue(buckets: [bucket, bucket])
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        guard case DequeueResult.dequeuedBucket(let dequeuedBucket) = dequeueResult else {
            return XCTFail("Unexpected dequeue result: \(dequeueResult)")
        }
        
        XCTAssertEqual(
            dequeuedBucket.enqueuedBucket.bucket,
            bucket,
            "Dequeued bucket must match enqueued bucket"
        )
        XCTAssertEqual(
            bucketQueue.runningQueueState.enqueuedBucketCount,
            1,
            "Dequeueing one of the similar buckets should correctly update queue state"
        )
    }
}

