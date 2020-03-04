import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import BuildArtifacts
import BuildArtifactsTestHelpers
import DateProviderTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueModels
import QueueModelsTestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class BalancingBucketQueueTests: XCTestCase {
    
    func test___state_check_throws___when_no_queue_exists_for_job() {
        XCTAssertThrowsError(try balancingQueue.state(jobId: jobId))
    }
    
    func test___result_check_throws___when_no_queue_exists_for_job() {
        XCTAssertThrowsError(try balancingQueue.results(jobId: jobId))
    }
    
    func test___state_has_enqueued_buckets___after_enqueueing_buckets_for_job() {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 1,
                        dequeuedBucketCount: 0
                    )
                )
            )
        )
    }
    
    func test___state_has_correct_enqueued_buckets___after_enqueueing_buckets_for_same_job() {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 2,
                        dequeuedBucketCount: 0
                    )
                )
            )
        )
    }
    
    func test___deleting_job() {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        XCTAssertNoThrow(try balancingQueue.delete(jobId: jobId))
    }
    
    func test___job_state_of_deleted_job() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        try balancingQueue.delete(jobId: jobId)
        XCTAssertEqual(
            try balancingQueue.state(jobId: jobId).queueState,
            .deleted
        )
    }
    
    func test___repeated_deletion_of_job_throws() {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        XCTAssertNoThrow(try balancingQueue.delete(jobId: jobId))
        XCTAssertThrowsError(try balancingQueue.delete(jobId: jobId))
    }
    
    func test___results_for_deleted_job_available() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        try balancingQueue.delete(jobId: jobId)
        XCTAssertNoThrow(_ = try balancingQueue.results(jobId: jobId))
    }
    
    func test___deleting_non_existing_job___throws() throws {
        XCTAssertThrowsError(try balancingQueue.delete(jobId: "non existing job id"))
    }
    
    func test___dequeueing_from_empty_qeueue___returns_check_after() {
        // we keep workers alive by asking them to poll
        // so when all queues are depleted, and somebody enqueues some tests, workers will pick them up
        XCTAssertEqual(
            balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId),
            .checkAgainLater(checkAfter: checkAgainTimeInterval)
        )
    }
    
    func test___dequeueing_bucket___after_enqueueing_it() {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                requestId: requestId,
                workerId: workerId
            ),
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
    
    func test___dequeueing_bucket_from_another_job___after_first_job_queue_has_all_buckets_dequeued() {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: anotherPrioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                requestId: requestId,
                workerId: workerId
            ),
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket1,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId,
                    requestId: requestId
                )
            )
        )
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0,
                        dequeuedBucketCount: 1
                    )
                )
            )
        )
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                requestId: anotherRequestId,
                workerId: workerId
            ),
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket2,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId,
                    requestId: anotherRequestId
                )
            )
        )
        XCTAssertEqual(
            try? balancingQueue.state(jobId: anotherJobId),
            JobState(
                jobId: anotherJobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0, 
                        dequeuedBucketCount: 1
                    )
                )
            )
        )
    }
    
    func test___dequeueing_bucket_from_job_with_priority() {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: highlyPrioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                requestId: requestId,
                workerId: workerId
            ),
            .dequeuedBucket(
                DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: bucket2,
                        enqueueTimestamp: dateProvider.currentDate(),
                        uniqueIdentifier: uniqueIdentifierGenerator.generate()
                    ),
                    workerId: workerId,
                    requestId: requestId
                )
            )
        )
    }
    
    func test___repeately_dequeueing_bucket___provides_back_same_result() {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        for _ in 0 ..< 10 {
            XCTAssertEqual(
                balancingQueue.dequeueBucket(
                    requestId: requestId,
                    workerId: workerId
                ),
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
                ),
                "Queue should return the same results again and again for the same workerId/requestId pair."
            )
        }
    }
    
    func test___reenqueueing_stuck_buckets___works_for_all_bucket_queues() {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: anotherPrioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: anotherRequestId, workerId: workerId)
        
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        XCTAssertEqual(
            balancingQueue.reenqueueStuckBuckets(),
            [
                StuckBucket(reason: .bucketLost, bucket: bucket1, workerId: workerId, requestId: requestId),
                StuckBucket(reason: .bucketLost, bucket: bucket2, workerId: workerId, requestId: anotherRequestId)
            ],
            "All buckets should be reenqueued since bucketIdsBeingProcessed == []"
        )
    }

    func test___getting_results_for_job_with_no_results___provides_back_empty_results() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(try balancingQueue.results(jobId: jobId).testingResults, [])
    }
    
    func test___accepting_results___provides_back_results_for_job() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let testEntry = TestEntryFixtures.testEntry(className: "class1")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let expectedTestingResult = TestingResultFixtures(
            bucketId: bucket.bucketId,
            testEntry: testEntry,
            manuallyTestDestination: bucket.testDestination,
            unfilteredResults: [
                TestEntryResult.withResult(
                    testEntry: testEntry,
                    testRunResult: TestRunResultFixtures.testRunResult()
                )
            ]
            ).testingResult()
        let expectedJobResults = JobResults(jobId: jobId, testingResults: [expectedTestingResult])
        
        let acceptanceResult = try balancingQueue.accept(
            testingResult: expectedTestingResult,
            requestId: requestId,
            workerId: workerId
        )
        
        XCTAssertEqual(acceptanceResult.testingResultToCollect, expectedTestingResult)
        XCTAssertEqual(try balancingQueue.results(jobId: jobId), expectedJobResults)
    }
    
    func test___accepting_results_for_deleted_job___does_not_throw() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let testEntry = TestEntryFixtures.testEntry(className: "class1")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        let expectedTestingResult = TestingResultFixtures(
            bucketId: bucket.bucketId,
            testEntry: testEntry,
            manuallyTestDestination: bucket.testDestination,
            unfilteredResults: [
                TestEntryResult.withResult(
                    testEntry: testEntry,
                    testRunResult: TestRunResultFixtures.testRunResult()
                )
            ]
            ).testingResult()
        
        try balancingQueue.delete(jobId: jobId)
        
        XCTAssertNoThrow(
            _ = try balancingQueue.accept(
                testingResult: expectedTestingResult,
                requestId: requestId,
                workerId: workerId
            )
        )
    }
    
    func test___accepting_results_for_wrong_request_id___throws() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertThrowsError(
            _ = try balancingQueue.accept(
                testingResult: TestingResultFixtures().testingResult(),
                requestId: "blah",
                workerId: workerId
            )
        )
    }
    
    func test___accepting_results_for_wrong_worker_id___throws() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(status: .alive, bucketIdsBeingProcessed: [])
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId)
        
        XCTAssertThrowsError(
            _ = try balancingQueue.accept(
                testingResult: TestingResultFixtures().testingResult(),
                requestId: requestId,
                workerId: "blah"
            )
        )
    }
    
    func test___dequeueing_by_silent_worker___when_buckets_enqueued___provides_silent_response() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(
            status: .silent(lastAlivenessResponseTimestamp: Date().addingTimeInterval(-100)),
            bucketIdsBeingProcessed: []
        )
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId),
            DequeueResult.workerIsNotAlive
        )
    }
    
    func test___dequeueing_by_blocked_worker___when_buckets_enqueued___provides_blocked_response() throws {
        workerAlivenessProvider.workerAliveness[workerId] = WorkerAliveness(
            status: .blocked,
            bucketIdsBeingProcessed: []
        )
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(requestId: requestId, workerId: workerId),
            DequeueResult.workerIsBlocked
        )
    }
    
    let dateProvider = DateProviderFixture()
    let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    let workerAlivenessProvider = MutableWorkerAlivenessProvider()
    let checkAgainTimeInterval: TimeInterval = 42
    lazy var bucketQueueFactory = BucketQueueFactory(
        checkAgainTimeInterval: checkAgainTimeInterval,
        dateProvider: dateProvider,
        testHistoryTracker: TestHistoryTrackerFixtures.testHistoryTracker(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        ),
        uniqueIdentifierGenerator: uniqueIdentifierGenerator,
        workerAlivenessProvider: workerAlivenessProvider
    )
    lazy var balancingBucketQueueFactory = BalancingBucketQueueFactory(
        bucketQueueFactory: bucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehaviorCheckLater(checkAfter: checkAgainTimeInterval)
    )
    lazy var balancingQueue = balancingBucketQueueFactory.create()
    let jobId: JobId = "jobId"
    lazy var prioritizedJob = PrioritizedJob(jobId: jobId, priority: .medium)
    let anotherJobId: JobId = "anotherJobId"
    lazy var anotherPrioritizedJob = PrioritizedJob(jobId: anotherJobId, priority: .medium)
    let highlyPrioritizedJobId: JobId = "highPriorityJobId"
    lazy var highlyPrioritizedJob = PrioritizedJob(jobId: highlyPrioritizedJobId, priority: .highest)
    let requestId: RequestId = "requestId"
    let workerId: WorkerId = "workerId"
    let anotherRequestId: RequestId = "anotherRequestId"
}
