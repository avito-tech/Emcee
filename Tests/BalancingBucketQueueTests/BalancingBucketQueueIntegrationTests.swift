import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import BuildArtifacts
import BuildArtifactsTestHelpers
import DateProviderTestHelpers
import Foundation
import MetricsExtensions
import QueueCommunication
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
import XCTest

final class BalancingBucketQueueIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
    }
    
    func test___state_check_throws___when_no_queue_exists_for_job() {
        XCTAssertThrowsError(try balancingQueue.state(jobId: jobId))
    }
    
    func test___result_check_throws___when_no_queue_exists_for_job() {
        XCTAssertThrowsError(try balancingQueue.results(jobId: jobId))
    }
    
    func test___state_has_enqueued_buckets___after_enqueueing_buckets_for_job() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 1,
                        enqueuedTests: bucket.testEntries.map { $0.testName },
                        dequeuedBucketCount: 0,
                        dequeuedTests: [:]
                    )
                )
            )
        )
    }
    
    func test___state_has_correct_enqueued_buckets___after_enqueueing_buckets_for_same_job() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 2,
                        enqueuedTests: bucket.testEntries.map { $0.testName } + bucket.testEntries.map { $0.testName },
                        dequeuedBucketCount: 0,
                        dequeuedTests: [:]
                    )
                )
            )
        )
    }
    
    func test___deleting_job() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        XCTAssertNoThrow(try balancingQueue.delete(jobId: jobId))
    }
    
    func test___job_state_of_deleted_job() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        try balancingQueue.delete(jobId: jobId)
        XCTAssertEqual(
            try balancingQueue.state(jobId: jobId).queueState,
            .deleted
        )
    }
    
    func test___repeated_deletion_of_job_throws() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        XCTAssertNoThrow(try balancingQueue.delete(jobId: jobId))
        XCTAssertThrowsError(try balancingQueue.delete(jobId: jobId))
    }
    
    func test___results_for_deleted_job_available() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        try balancingQueue.delete(jobId: jobId)
        XCTAssertNoThrow(_ = try balancingQueue.results(jobId: jobId))
    }
    
    func test___deleting_non_existing_job___throws() throws {
        XCTAssertThrowsError(try balancingQueue.delete(jobId: "non existing job id"))
    }
    
    func test___dequeueing_from_empty_qeueue___returns_check_after() {
        // we keep workers alive by asking them to poll
        // so when all queues are depleted, and somebody enqueues some tests, workers will pick them up
        XCTAssertNil(
            balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        )
    }
    
    func test___dequeueing_bucket___after_enqueueing_it() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                workerCapabilities: [],
                workerId: workerId
            ),
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                ),
                workerId: workerId
            )
        )
    }
    
    func test___dequeueing_bucket_from_another_job___after_first_job_queue_has_all_buckets_dequeued() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        try balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        try balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: anotherPrioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                workerCapabilities: [],
                workerId: workerId
            ),
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket1,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                ),
                workerId: workerId
            )
        )
        XCTAssertEqual(
            try? balancingQueue.state(jobId: jobId),
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0,
                        enqueuedTests: [],
                        dequeuedBucketCount: 1,
                        dequeuedTests: [workerId: bucket1.testEntries.map { $0.testName }]
                    )
                )
            )
        )
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                workerCapabilities: [],
                workerId: workerId
            ),
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket2,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                ),
                workerId: workerId
            )
        )
        XCTAssertEqual(
            try? balancingQueue.state(jobId: anotherJobId),
            JobState(
                jobId: anotherJobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0,
                        enqueuedTests: [],
                        dequeuedBucketCount: 1,
                        dequeuedTests: [workerId: bucket2.testEntries.map { $0.testName }]
                    )
                )
            )
        )
    }
    
    func test___dequeueing_bucket_from_job_with_priority() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        try balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        try balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: highlyPrioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                workerCapabilities: [],
                workerId: workerId
            ),
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket2,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                ),
                workerId: workerId
            )
        )
    }
    
    func test___dequeueing_bucket_with_job_groups_with_priority() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)

        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        try balancingQueue.enqueue(
            buckets: [bucket1],
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: analyticsConfiguration,
                jobGroupId: "group1",
                jobGroupPriority: .medium,
                jobId: "job1",
                jobPriority: .medium,
                persistentMetricsJobId: ""
            )
        )
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        try balancingQueue.enqueue(
            buckets: [bucket2],
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: analyticsConfiguration,
                jobGroupId: "group2",
                jobGroupPriority: .highest,
                jobId: "job2",
                jobPriority: .medium,
                persistentMetricsJobId: ""
            )
        )

        XCTAssertEqual(
            balancingQueue.dequeueBucket(
                workerCapabilities: [],
                workerId: workerId
            ),
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket2,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                ),
                workerId: workerId
            )
        )
    }
    
    func test___reenqueueing_stuck_buckets___works_for_all_bucket_queues() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket1 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class1")])
        try balancingQueue.enqueue(buckets: [bucket1], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let bucket2 = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "class2")])
        try balancingQueue.enqueue(buckets: [bucket2], prioritizedJob: anotherPrioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        XCTAssertEqual(
            balancingQueue.reenqueueStuckBuckets(),
            [
                StuckBucket(reason: .bucketLost, bucket: bucket1, workerId: workerId),
                StuckBucket(reason: .bucketLost, bucket: bucket2, workerId: workerId)
            ],
            "All buckets should be reenqueued since bucketIdsBeingProcessed == []"
        )
    }

    func test___getting_results_for_job_with_no_results___provides_back_empty_results() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(try balancingQueue.results(jobId: jobId).testingResults, [])
    }
    
    func test___accepting_results___provides_back_results_for_job() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class1")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let expectedTestingResult = TestingResultFixtures(
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
            bucketId: bucket.bucketId,
            testingResult: expectedTestingResult,
            workerId: workerId
        )
        
        XCTAssertEqual(acceptanceResult.testingResultToCollect, expectedTestingResult)
        XCTAssertEqual(try balancingQueue.results(jobId: jobId), expectedJobResults)
    }
    
    func test___accepting_results_for_deleted_job___does_not_throw() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let testEntry = TestEntryFixtures.testEntry(className: "class1")
        let bucket = BucketFixtures.createBucket(testEntries: [testEntry])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        let expectedTestingResult = TestingResultFixtures(
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
                bucketId: bucket.bucketId,
                testingResult: expectedTestingResult,
                workerId: workerId
            )
        )
    }
    
    func test___accepting_results_for_wrong_bucket_id___throws() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        assertThrows {
            _ = try balancingQueue.accept(
                bucketId: "wrong bucket id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: workerId
            )
        }
    }
    
    func test___accepting_results_for_wrong_worker_id___throws() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry()])
        try balancingQueue.enqueue(buckets: [bucket], prioritizedJob: prioritizedJob)
        _ = balancingQueue.dequeueBucket(workerCapabilities: [], workerId: workerId)
        
        XCTAssertThrowsError(
            _ = try balancingQueue.accept(
                bucketId: bucket.bucketId,
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "blah"
            )
        )
    }
    
    func test___ongoing_job_ids() throws {
        try balancingQueue.enqueue(buckets: [], prioritizedJob: prioritizedJob)
        try balancingQueue.enqueue(buckets: [], prioritizedJob: highlyPrioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.ongoingJobIds,
            Set([highlyPrioritizedJob.jobId, prioritizedJob.jobId])
        )
    }
    
    func test___scheduling_job___appends_to_ongoing_job_groups() throws {
        try balancingQueue.enqueue(buckets: [], prioritizedJob: prioritizedJob)
        
        XCTAssertEqual(
            balancingQueue.ongoingJobGroupIds,
            [prioritizedJob.jobGroupId]
        )
    }
    
    func test___removing_not_last_job_in_group___keeps_group_in_ongoing_job_groups() throws {
        try balancingQueue.enqueue(buckets: [], prioritizedJob: prioritizedJob)
        try balancingQueue.enqueue(buckets: [], prioritizedJob: highlyPrioritizedJob)
        assertDoesNotThrow {
            try balancingQueue.delete(jobId: prioritizedJob.jobId)
        }
        
        XCTAssertEqual(
            balancingQueue.ongoingJobGroupIds,
            [highlyPrioritizedJob.jobGroupId]
        )
    }
    
    func test___removing_last_job_in_group___removes_group_from_ongoing_job_groups() throws {
        try balancingQueue.enqueue(buckets: [], prioritizedJob: prioritizedJob)
        assertDoesNotThrow {
            try balancingQueue.delete(jobId: prioritizedJob.jobId)
        }
        
        XCTAssertTrue(
            balancingQueue.ongoingJobGroupIds.isEmpty
        )
    }
    
    lazy var analyticsConfiguration = AnalyticsConfiguration()
    
    lazy var anotherJobId: JobId = "anotherJobId"
    lazy var anotherPrioritizedJob = PrioritizedJob(
        analyticsConfiguration: analyticsConfiguration,
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: anotherJobId,
        jobPriority: .medium,
        persistentMetricsJobId: ""
    )
    lazy var balancingQueue = BalancingBucketQueueImpl(
        bucketQueueFactory: bucketQueueFactory,
        dateProvider: dateProvider,
        emceeVersion: Version("version")
    )
    lazy var bucketQueueFactory = BucketQueueFactoryImpl(
        dateProvider: dateProvider,
        testHistoryTracker: TestHistoryTrackerFixtures.testHistoryTracker(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
        ),
        uniqueIdentifierGenerator: uniqueIdentifierGenerator,
        workerAlivenessProvider: workerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorageImpl()
    )
    lazy var checkAgainTimeInterval: TimeInterval = 42
    lazy var dateProvider = DateProviderFixture()
    lazy var highlyPrioritizedJob = PrioritizedJob(
        analyticsConfiguration: analyticsConfiguration,
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: highlyPrioritizedJobId,
        jobPriority: .highest,
        persistentMetricsJobId: ""
    )
    lazy var highlyPrioritizedJobId: JobId = "highPriorityJobId"
    lazy var jobId: JobId = "jobId"
    lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: analyticsConfiguration,
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: jobId,
        jobPriority: .medium,
        persistentMetricsJobId: ""
    )
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: [workerId],
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerId: WorkerId = "workerId"
}
