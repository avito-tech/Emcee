import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesEnqueueableBucketReceptorTests: XCTestCase {
    lazy var bucketQueueFactory = FakeBucketQueueFactory()
    lazy var container = MultipleQueuesContainer()
    lazy var prioritizedJob = PrioritizedJob(
        jobGroupId: "group",
        jobGroupPriority: .medium,
        jobId: "job",
        jobPriority: .medium,
        persistentMetricsJobId: ""
    )
    lazy var receptor = MultipleQueuesEnqueueableBucketReceptor(
        bucketQueueFactory: bucketQueueFactory,
        multipleQueuesContainer: container
    )
    
    func test___enqueueing_to_new_job___creates_job_queue() {
        var createdBucketQueue: FakeBucketQueue?
        bucketQueueFactory.tuner = { createdBucketQueue = $0 }
        
        
        let bucket = BucketFixtures.createBucket()
        
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
        
        XCTAssertEqual(createdBucketQueue?.enqueuedBuckets, [bucket])
    }
    
    func test___enqueueing_to_existing_job___appends_buckets_to_it() {
        let bucketQueue = FakeBucketQueue()
        
        container.add(
            runningJobQueue: createJobQueue(
                bucketQueue: bucketQueue,
                job: createJob(jobId: prioritizedJob.jobId),
                jobGroup: createJobGroup(jobGroupId: prioritizedJob.jobGroupId)
            )
        )
                
        let bucket = BucketFixtures.createBucket()
        
        assertDoesNotThrow {
            try receptor.enqueue(
                buckets: [bucket],
                prioritizedJob: prioritizedJob
            )
        }
        
        XCTAssertEqual(bucketQueue.enqueuedBuckets, [bucket])
    }
    
    func test___enqueueing_to_deleted_job___removes_all_buckets_and_moves_job_to_running() {
        let bucketQueue = FakeBucketQueue()
        
        container.add(
            deletedJobQueues: [
                createJobQueue(
                    bucketQueue: bucketQueue,
                    job: createJob(jobId: prioritizedJob.jobId),
                    jobGroup: createJobGroup(jobGroupId: prioritizedJob.jobGroupId)
                )
            ]
        )
                
        let bucket = BucketFixtures.createBucket()
        
        assertDoesNotThrow {
            try receptor.enqueue(
                buckets: [bucket],
                prioritizedJob: prioritizedJob
            )
        }
        
        XCTAssertEqual(bucketQueue.enqueuedBuckets, [bucket])
        XCTAssertTrue(container.allDeletedJobQueues().isEmpty)
        XCTAssertTrue(bucketQueue.removedAllEnqueuedBuckets)
        XCTAssertEqual(bucketQueue.enqueuedBuckets, [bucket])
    }
}
