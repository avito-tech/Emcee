import DateProvider
import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import Foundation
import MetricsExtensions
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TestHelpers
import TestHistoryStorage
import TestHistoryTracker
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers

final class IntegrationTests: XCTestCase {
    // Misc
    
    private lazy var dateProvider = SystemDateProvider()
    private lazy var workerPermissionProvider = FakeWorkerPermissionProvider()
    private lazy var uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
    private lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        logger: .noOp,
        workerPermissionProvider: workerPermissionProvider
    )
    
    // Models
    
    private lazy var jobId: JobId = "jobId"
    private lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: jobId,
        jobPriority: .medium
    )
    
    private lazy var highlyPrioritizedJobId: JobId = "highPriorityJobId"
    private lazy var highlyPrioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "groupId",
        jobGroupPriority: .medium,
        jobId: highlyPrioritizedJobId,
        jobPriority: .highest
    )
    
    private lazy var workerId: WorkerId = "workerId"
    
    // Main stuff under testing
    
    private lazy var testHistoryTracker = TestHistoryTrackerImpl(
        testHistoryStorage: TestHistoryStorageImpl(),
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private lazy var bucketEnqueuerProvider = SingleBucketQueueEnqueuerProvider(
        dateProvider: dateProvider,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator,
        workerAlivenessProvider: workerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorageImpl()
    )
    private lazy var testingResultAcceptorProvider = TestingResultAcceptorProviderImpl(
        bucketEnqueuerProvider: bucketEnqueuerProvider,
        logger: .noOp,
        testHistoryTracker: testHistoryTracker,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    private lazy var bucketResultAcceptorProvider = SingleBucketResultAcceptorProvider(
        logger: .noOp,
        testingResultAcceptorProvider: testingResultAcceptorProvider
    )
    private lazy var stuckBucketsReenqueuerProvider = SingleBucketQueueStuckBucketsReenqueuerProvider(
        logger: .noOp,
        bucketEnqueuerProvider: bucketEnqueuerProvider,
        workerAlivenessProvider: workerAlivenessProvider,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    
    private lazy var multipleQueuesContainer = MultipleQueuesContainer()
    private lazy var multipleQueuesEnqueueableBucketReceptor = MultipleQueuesEnqueueableBucketReceptor(
        bucketEnqueuerProvider: bucketEnqueuerProvider,
        emptyableBucketQueueProvider: SingleEmptyableBucketQueueProvider(),
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var multipleQueuesJobStateProvider = MultipleQueuesJobStateProvider(
        multipleQueuesContainer: multipleQueuesContainer,
        statefulBucketQueueProvider: SingleStatefulBucketQueueProvider()
    )
    private lazy var multipleQueuesJobManipulator = MultipleQueuesJobManipulator(
        dateProvider: dateProvider,
        specificMetricRecorderProvider: SpecificMetricRecorderProviderImpl(
            mutableMetricRecorderProvider: MutableMetricRecorderProviderImpl(
                queue: .global()
            )
        ),
        multipleQueuesContainer: multipleQueuesContainer,
        emceeVersion: Version("doesnotmatter")
    )
    private lazy var multipleQueuesJobResultsProvider = MultipleQueuesJobResultsProvider(
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var multipleQueuesDequeueableBucketSource = MultipleQueuesDequeueableBucketSource(
        dequeueableBucketSourceProvider: SingleBucketQueueDequeueableBucketSourceProvider(
            logger: .noOp,
            testHistoryTracker: testHistoryTracker,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: WorkerCapabilitiesStorageImpl(),
            workerCapabilityConstraintResolver: WorkerCapabilityConstraintResolver()
        ),
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var multipleQueuesBucketResultAcceptor = MultipleQueuesBucketResultAcceptor(
        bucketResultAcceptorProvider: bucketResultAcceptorProvider,
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var multipleQueuesStuckBucketsReenqueuer = MultipleQueuesStuckBucketsReenqueuer(
        multipleQueuesContainer: multipleQueuesContainer,
        stuckBucketsReenqueuerProvider: stuckBucketsReenqueuerProvider
    )
    
    override func setUp() {
        super.setUp()
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
    }
    
    private func enqueue(bucket: Bucket, prioritizedJob: PrioritizedJob? = nil) throws {
        try multipleQueuesEnqueueableBucketReceptor.enqueue(
            buckets: [bucket],
            prioritizedJob: prioritizedJob ?? self.prioritizedJob
        )
    }
    
    private func deleteJob(jobId: JobId? = nil) throws {
        try multipleQueuesJobManipulator.delete(
            jobId: jobId ?? prioritizedJob.jobId
        )
    }
    
    private func dequeue(
        workerCapabilities: Set<WorkerCapability> = [],
        workerId: WorkerId? = nil
    ) -> DequeuedBucket? {
        multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: workerCapabilities,
            workerId: workerId ?? self.workerId
        )
    }
    
    private func submitResult(
        bucketId: BucketId,
        bucketResult: BucketResult = .testingResult(
            TestingResultFixtures().testingResult()
        ),
        workerId: WorkerId? = nil
    ) throws -> BucketQueueAcceptResult {
        try multipleQueuesBucketResultAcceptor.accept(
            bucketId: bucketId,
            bucketResult: bucketResult,
            workerId: workerId ?? self.workerId
        )
    }
    
    private func imitateWorkerLoosingItsBuckets(
        workerId: WorkerId? = nil
    ) {
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId ?? self.workerId)
    }
    
    // Tests
    
    func test___state_has_enqueued_buckets___after_enqueueing_buckets_for_job() throws {
        let payload = BucketFixtures.createRunIosTestsPayload()
        let bucket = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(payload)
        )
        
        try enqueue(bucket: bucket)
        
        assert {
            try multipleQueuesJobStateProvider.state(jobId: prioritizedJob.jobId)
        } equals: {
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 1,
                        enqueuedTests: payload.testEntries.map { $0.testName },
                        dequeuedBucketCount: 0,
                        dequeuedTests: [:]
                    )
                )
            )
        }
    }
    
    func test___state_has_correct_enqueued_buckets___after_enqueueing_buckets_for_same_job() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        try enqueue(bucket: bucket)
        
        assert {
            try multipleQueuesJobStateProvider.state(jobId: prioritizedJob.jobId)
        } equals: {
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 2,
                        enqueuedTests: [
                            TestEntryFixtures.testEntry().testName,
                            TestEntryFixtures.testEntry().testName,
                        ],
                        dequeuedBucketCount: 0,
                        dequeuedTests: [:]
                    )
                )
            )
        }
    }
    
    func test___deleting_job() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        
        assertDoesNotThrow {
            try deleteJob()
        }
    }
    
    func test___deleting_non_existing_job___throws() {
        assertThrows {
            try deleteJob(jobId: "Unknown")
        }
    }
    
    func test___state_of_deleted_job() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        try deleteJob()
        
        assert {
            try multipleQueuesJobStateProvider.state(jobId: prioritizedJob.jobId)
        } equals: {
            JobState(
                jobId: jobId,
                queueState: QueueState.deleted
            )
        }
    }
    
    func test___repeated_deletion_of_job_throws() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        try deleteJob()
        
        assertThrows {
            try deleteJob()
        }
    }
    
    func test___results_for_deleted_job_available() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        try deleteJob()
        
        assert {
            try multipleQueuesJobResultsProvider.results(
                jobId: prioritizedJob.jobId
            )
        } equals: {
            JobResults(
                jobId: prioritizedJob.jobId,
                bucketResults: []
            )
        }
    }
    
    func test___dequeueing_from_empty_qeueue___returns_nil() {
        assertTrue {
            dequeue()  == nil
        }
    }
    
    func test___dequeueing_bucket___after_enqueueing_it() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        
        assert {
            dequeue()?.enqueuedBucket.bucket
        } equals: {
            bucket
        }
    }
    
    func test___dequeueing_bucket_from_another_job___after_first_job_queue_has_all_buckets_dequeued() throws {
        let anotherJob = JobId("anotherJob")
        let anotherPrioritizedJob = PrioritizedJob(
            analyticsConfiguration: AnalyticsConfiguration(),
            jobGroupId: "anotherGroupId",
            jobGroupPriority: .medium,
            jobId: anotherJob,
            jobPriority: .medium
        )
        
        let bucket1 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class1")]
                )
            )
        )
        try enqueue(bucket: bucket1, prioritizedJob: prioritizedJob)
        
        let bucket2 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class2")]
                )
            )
        )
        try enqueue(bucket: bucket2, prioritizedJob: anotherPrioritizedJob)
        
        assert {
            dequeue()?.enqueuedBucket.bucket
        } equals: {
            bucket1
        }
        
        assert {
            try multipleQueuesJobStateProvider.state(jobId: jobId)
        } equals: {
            JobState(
                jobId: jobId,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0,
                        enqueuedTests: [],
                        dequeuedBucketCount: 1,
                        dequeuedTests: [
                            workerId: [TestName(className: "class1", methodName: "test")],
                        ]
                    )
                )
            )
        }
        
        assert {
            dequeue()?.enqueuedBucket.bucket
        } equals: {
            bucket2
        }
        
        assert {
            try multipleQueuesJobStateProvider.state(jobId: anotherJob)
        } equals: {
            JobState(
                jobId: anotherJob,
                queueState: QueueState.running(
                    RunningQueueState(
                        enqueuedBucketCount: 0,
                        enqueuedTests: [],
                        dequeuedBucketCount: 1,
                        dequeuedTests: [
                            workerId: [TestName(className: "class2", methodName: "test")],
                        ]
                    )
                )
            )
        }
    }
    
    func test___dequeueing_bucket_from_job_with_priority() throws {
        let bucket1 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class1")]
                )
            )
        )
        try enqueue(bucket: bucket1, prioritizedJob: prioritizedJob)
        
        let bucket2 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class2")]
                )
            )
        )
        try enqueue(bucket: bucket2, prioritizedJob: highlyPrioritizedJob)
        
        assert {
            dequeue()?.enqueuedBucket.bucket
        } equals: {
            bucket2
        }
    }
    
    func test___dequeueing_bucket_with_job_groups_with_priority() throws {
        let bucket1 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class1")]
                )
            )
        )
        try enqueue(
            bucket: bucket1,
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(),
                jobGroupId: "group1",
                jobGroupPriority: .medium,
                jobId: "job1",
                jobPriority: .medium
            )
        )
        
        let bucket2 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class2")]
                )
            )
        )
        try enqueue(
            bucket: bucket2,
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(),
                jobGroupId: "group2",
                jobGroupPriority: .highest,
                jobId: "job2",
                jobPriority: .medium
            )
        )
        
        assert {
            dequeue()?.enqueuedBucket.bucket
        } equals: {
            bucket2
        }
    }
    
    func test___reenqueueing_stuck_buckets___works_for_all_bucket_queues() throws {
        let bucket1 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class1")]
                )
            )
        )
        try enqueue(bucket: bucket1, prioritizedJob: prioritizedJob)
        assertNotNil {
            dequeue()
        }
        
        let bucket2 = BucketFixtures.createBucket(
            bucketPayloadContainer: .runIosTests(
                BucketFixtures.createRunIosTestsPayload(
                    testEntries: [TestEntryFixtures.testEntry(className: "class2")]
                )
            )
        )
        try enqueue(bucket: bucket2, prioritizedJob: highlyPrioritizedJob)
        assertNotNil {
            dequeue()
        }
        
        imitateWorkerLoosingItsBuckets()
        
        assert {
            try multipleQueuesStuckBucketsReenqueuer.reenqueueStuckBuckets()
        } equals: {
            [
                StuckBucket(reason: .bucketLost, bucket: bucket2, workerId: workerId),
                StuckBucket(reason: .bucketLost, bucket: bucket1, workerId: workerId),
            ]
        }
    }
    
    func test___getting_results_for_job_with_no_results___provides_back_empty_results() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        
        assert {
            try multipleQueuesJobResultsProvider.results(jobId: jobId)
        } equals: {
            JobResults(jobId: jobId, bucketResults: [])
        }
    }
    
    func test___accepting_results___provides_back_results_for_job() throws {
        let bucket = BucketFixtures.createBucket()
        let expectedBucketResult = BucketResult.testingResult(
            TestingResultFixtures(
                testEntry: TestEntryFixtures.testEntry(),
                manuallyTestDestination: TestDestinationFixtures.testDestination,
                unfilteredResults: [
                    TestEntryResult.withResult(
                        testEntry: TestEntryFixtures.testEntry(),
                        testRunResult: TestRunResultFixtures.testRunResult()
                    )
                ]
            ).testingResult()
        )
        
        try enqueue(bucket: bucket)
        assertNotNil {
            dequeue()
        }
        
        assert {
            try submitResult(
                bucketId: bucket.bucketId,
                bucketResult: expectedBucketResult,
                workerId: workerId
            ).bucketResultToCollect
        } equals: {
            expectedBucketResult
        }
        
        assert {
            try multipleQueuesJobResultsProvider.results(jobId: jobId)
        } equals: {
            JobResults(
                jobId: jobId,
                bucketResults: [expectedBucketResult]
            )
        }
    }
    
    func test___accepting_results_for_deleted_job___does_not_throw() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket()
        let expectedBucketResult = BucketResult.testingResult(
            TestingResultFixtures(
                testEntry: TestEntryFixtures.testEntry(),
                manuallyTestDestination: TestDestinationFixtures.testDestination,
                unfilteredResults: [
                    TestEntryResult.withResult(
                        testEntry: TestEntryFixtures.testEntry(),
                        testRunResult: TestRunResultFixtures.testRunResult()
                    )
                ]
            ).testingResult()
        )
        
        try enqueue(bucket: bucket)
        assertNotNil {
            dequeue()
        }
        try deleteJob()
        
        assert {
            try submitResult(
                bucketId: bucket.bucketId,
                bucketResult: expectedBucketResult
            ).dequeuedBucket.enqueuedBucket.bucket
        } equals: {
            bucket
        }
    }
    
    func test___accepting_results_for_wrong_bucket_id___throws() throws {
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        assertNotNil {
            dequeue()
        }
        
        assertThrows {
            try submitResult(
                bucketId: "wrong bucket id"
            )
        }
    }
    
    func test___accepting_results_for_wrong_worker_id___throws() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        let bucket = BucketFixtures.createBucket()
        
        try enqueue(bucket: bucket)
        assertNotNil {
            dequeue()
        }
        
        assertThrows {
            try submitResult(
                bucketId: bucket.bucketId,
                workerId: "wrongWorkerId"
            )
        }
    }
    
    func test___ongoing_job_ids() throws {
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: prioritizedJob)
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: highlyPrioritizedJob)
        
        assert {
            multipleQueuesJobStateProvider.ongoingJobIds
        } equals: {
            [highlyPrioritizedJob.jobId, prioritizedJob.jobId]
        }
    }
    
    func test___scheduling_job___appends_to_ongoing_job_groups() throws {
        assert { prioritizedJob.jobGroupId } equals: { highlyPrioritizedJob.jobGroupId }
        
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: prioritizedJob)
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: highlyPrioritizedJob)
        
        assert {
            multipleQueuesJobStateProvider.ongoingJobGroupIds
        } equals: {
            [prioritizedJob.jobGroupId]
        }
    }
    
    func test___if_after_deleting_job_job_group_contains_other_jobs___job_group_is_kept_in_ongoing_job_groups() throws {
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: prioritizedJob)
        try enqueue(bucket: BucketFixtures.createBucket(), prioritizedJob: highlyPrioritizedJob)
        
        try deleteJob()
        
        assert {
            multipleQueuesJobStateProvider.ongoingJobGroupIds
        } equals: {
            [highlyPrioritizedJob.jobGroupId]
        }
    }
    
    
    func test___removing_last_job_in_group___removes_group_from_ongoing_job_groups() throws {
        let bucket = BucketFixtures.createBucket()
        try enqueue(bucket: bucket)
        try deleteJob()
        
        assertTrue {
            multipleQueuesJobStateProvider.ongoingJobGroupIds.isEmpty
        }
    }
}

