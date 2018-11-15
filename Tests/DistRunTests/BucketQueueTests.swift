@testable import DistRun
import Foundation
import Models
import ModelsTestHelpers
import RESTMethods
import XCTest

final class BucketQueueTests: XCTestCase {
    let workerConfigurations = WorkerConfigurations()
    
    let workerId = "worker_id"
    let requestId = "request_id"
    let alivenessTrackerWithImmediateTimeout = FakeWorkerAlivenessTracker.alivenessTrackerWithImmediateTimeout()
    let alivenessTrackerWithAlwaysAliveResults = FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults()
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test__whenQueueIsCreated__it_is_depleted() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        XCTAssertTrue(bucketQueue.state.isDepleted)
    }
    
    func test__if_buckets_enqueued__queue_is_not_depleted() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [])])
        XCTAssertFalse(bucketQueue.state.isDepleted)
    }
    
    func test__if_buckets_dequeued__queue_is_not_depleted() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [BucketFixtures.createBucket(testEntries: [])])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertFalse(bucketQueue.state.isDepleted)
    }
    
    func test__when_all_results_accepted__queue_is_depleted() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [])
        XCTAssertNoThrow(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId))
        
        XCTAssertTrue(bucketQueue.state.isDepleted)
    }
    
    func test__reponse_dequeuedBucket__when_dequeueing_buckets() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(dequeueResult, .dequeuedBucket(DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)))
    }
    
    func test__reponse_queueIsEmpty__when_dequeueing_bucket_from_empty_queue() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(dequeueResult, .queueIsEmpty)
    }
    
    func test__reponse_queueIsEmptyButNotAllResultsAreAvailable__when_queue_has_dequeued_buckets() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let dequeueResult = bucketQueue.dequeueBucket(requestId: "some other request", workerId: workerId)
        XCTAssertEqual(dequeueResult, .queueIsEmptyButNotAllResultsAreAvailable)
    }
    
    func test__reponse_workerBlocked__when_worker_is_blocked() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults)
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        XCTAssertNoThrow(try workerRegistrar.handle(decodedRequest: RegisterWorkerRequest(workerId: workerId)))
        
        workerRegistrar.blockWorker(workerId: workerId)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults,
            workerRegistrar: workerRegistrar)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        bucketQueue.enqueue(buckets: [bucket])
        
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        XCTAssertEqual(dequeueResult, .workerBlocked)
    }
    
    func test__dequeueing_previously_dequeued_buckets() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        let dequeueResult = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertEqual(dequeueResult, .dequeuedBucket(DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)))
    }
    
    func test__accepting_correct_results() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [TestEntryResult.lost(testEntry: testEntry)])
        XCTAssertNoThrow(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId))
    }
    
    func test__accepting_result_with_missing_tests_blocks_wotker() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults,
            workerRegistrar: workerRegistrar)
        
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let testingResult = TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
            unfilteredResults: [ /* empty - misses testEntry */ ])
        XCTAssertThrowsError(try bucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId))
        XCTAssertTrue(workerRegistrar.isWorkerBlocked(workerId: workerId))
    }
    
    func test__accepting_result_for_nonexisting_request_id_throws() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults,
            workerRegistrar: workerRegistrar)
        
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
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
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        
        let testEntry = TestEntry(className: "class", methodName: "test", caseId: nil)
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
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithImmediateTimeout)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithImmediateTimeout,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let stuckBuckets = bucketQueue.removeStuckBuckets()
        XCTAssertEqual(stuckBuckets, [StuckBucket(reason: .workerIsSilent, bucket: bucket, workerId: workerId)])
    }
    
    func test__when_worker_is_blocked__its_dequeued_buckets_removed() {
        let workerRegistrar = createWorkerRegistrat(workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults)
        
        let bucket = BucketFixtures.createBucket(testEntries: [])
        
        let bucketQueue = BucketQueueFactory.create(
            workerAlivenessTracker: alivenessTrackerWithAlwaysAliveResults,
            workerRegistrar: workerRegistrar)
        bucketQueue.enqueue(buckets: [bucket])
        _ = bucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        workerRegistrar.blockWorker(workerId: workerId)
        let stuckBuckets = bucketQueue.removeStuckBuckets()
        XCTAssertEqual(stuckBuckets, [StuckBucket(reason: .workerIsBlocked, bucket: bucket, workerId: workerId)])
    }
    
    private func createWorkerRegistrat(workerAlivenessTracker: WorkerAlivenessTracker) -> WorkerRegistrar {
        let workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: workerAlivenessTracker)
        workerConfigurations.add(workerId: workerId, configuration: WorkerConfigurationFixtures.workerConfiguration)
        XCTAssertNoThrow(try workerRegistrar.handle(decodedRequest: RegisterWorkerRequest(workerId: workerId)))
        return workerRegistrar
    }
}
