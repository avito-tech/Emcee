import BalancingBucketQueue
import BucketQueueTestHelpers
import MetricsExtensions
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesEnqueueableBucketReceptorTests: XCTestCase {
    lazy var container = MultipleQueuesContainer()
    lazy var prioritizedJob = PrioritizedJob(
        analyticsConfiguration: AnalyticsConfiguration(),
        jobGroupId: "group",
        jobGroupPriority: .medium,
        jobId: "job",
        jobPriority: .medium
    )
            
    lazy var bucketEnqueuerProvider = FakeBucketEnqueuerProvider()
    lazy var emptyableBucketQueueProvider = FakeEmptyableBucketQueueProvider()
    lazy var receptor = MultipleQueuesEnqueueableBucketReceptor(
        bucketEnqueuerProvider: bucketEnqueuerProvider,
        emptyableBucketQueueProvider: emptyableBucketQueueProvider,
        multipleQueuesContainer: container
    )
    
    func test___enqueueing_to_new_job___creates_job_queue__and_then_enqueues() {
        let bucket = BucketFixtures().bucket()
        
        let enqueueRoutineInvoked = XCTestExpectation()
        bucketEnqueuerProvider.fakeBucketEnqueuer.onEnqueue = { buckets in
            assert {
                buckets
            } equals: {
                [bucket]
            }
            enqueueRoutineInvoked.fulfill()
        }
        
        assertDoesNotThrow {
            try receptor.enqueue(
                buckets: [bucket],
                prioritizedJob: prioritizedJob
            )
        }
        
        XCTAssertEqual(
            container.allRunningJobQueues().map { $0.job.jobId },
            [prioritizedJob.jobId]
        )
        
        XCTAssertEqual(
            container.trackedJobGroups().map { $0.jobGroupId },
            [prioritizedJob.jobGroupId]
        )
        
        wait(for: [enqueueRoutineInvoked], timeout: 15)
    }
    
    func test___enqueueing_to_existing_job___appends_buckets_to_it() {
        let runningJobQueue = createJobQueue(
            job: createJob(jobId: prioritizedJob.jobId),
            jobGroup: createJobGroup(jobGroupId: prioritizedJob.jobGroupId)
        )
        container.add(
            runningJobQueue: runningJobQueue
        )
        
        let bucket = BucketFixtures().bucket()
        
        XCTAssertEqual(
            container.allRunningJobQueues()[0].bucketQueueHolder.allEnqueuedBuckets.map { $0.bucket },
            []
        )
        
        let enqueueRoutineInvoked = XCTestExpectation()
        bucketEnqueuerProvider.fakeBucketEnqueuer.onEnqueue = { buckets in
            assert {
                buckets
            } equals: {
                [bucket]
            }
            enqueueRoutineInvoked.fulfill()
        }
        
        assertDoesNotThrow {
            try receptor.enqueue(
                buckets: [bucket],
                prioritizedJob: prioritizedJob
            )
        }
        wait(for: [enqueueRoutineInvoked], timeout: 15)
        
        assert {
            container.allRunningJobQueues().map { $0.job.jobId }
        } equals: {
            [runningJobQueue.job.jobId]
        }
    }
    
    func test___enqueueing_to_deleted_job___removes_all_buckets_from_it_and_moves_job_into_running___and_enqueues() {
        container.add(
            deletedJobQueues: [
                createJobQueue(
                    job: createJob(jobId: prioritizedJob.jobId),
                    jobGroup: createJobGroup(jobGroupId: prioritizedJob.jobGroupId)
                )
            ]
        )
                
        let bucket = BucketFixtures().bucket()
        
        var didRemoveBucketsFromQueue = false
        emptyableBucketQueueProvider.fakeEmptyableBucketQueue.onRemoveAllEnqueuedBuckets = {
            didRemoveBucketsFromQueue = true
        }
        
        let enqueueRoutineInvoked = XCTestExpectation()
        bucketEnqueuerProvider.fakeBucketEnqueuer.onEnqueue = { buckets in
            assert {
                buckets
            } equals: {
                [bucket]
            }
            enqueueRoutineInvoked.fulfill()
        }
        
        assertDoesNotThrow {
            try receptor.enqueue(
                buckets: [bucket],
                prioritizedJob: prioritizedJob
            )
        }
        
        XCTAssertTrue(container.allDeletedJobQueues().isEmpty)
        XCTAssertTrue(didRemoveBucketsFromQueue)
    }
}
