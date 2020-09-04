import BalancingBucketQueue
import BucketQueueTestHelpers
import Foundation
import QueueModels
import RunnerModels
import TestHelpers
import XCTest

final class MultipleQueuesJobStateProviderTests: XCTestCase {
    lazy var container = MultipleQueuesContainer()
    lazy var multipleQueuesJobStateProvider = MultipleQueuesJobStateProvider(
        multipleQueuesContainer: container
    )
    
    func test___ongoing_group_ids() {
        container.track(jobGroup: createJobGroup(jobGroupId: "groupId1"))
        container.track(jobGroup: createJobGroup(jobGroupId: "groupId2"))
        
        XCTAssertEqual(
            multipleQueuesJobStateProvider.ongoingJobGroupIds,
            [
                JobGroupId("groupId1"),
                JobGroupId("groupId2"),
            ]
        )
    }
    
    func test___ongoing_jon_ids() {
        container.add(runningJobQueue: createJobQueue(job: createJob(jobId: "jobId1")))
        container.add(runningJobQueue: createJobQueue(job: createJob(jobId: "jobId2")))
        
        XCTAssertEqual(
            multipleQueuesJobStateProvider.ongoingJobIds,
            [
                JobId("jobId1"),
                JobId("jobId2"),
            ]
        )
    }
    
    func test___job_state___for_running_job() {
        let bucketQueue = FakeBucketQueue()
        bucketQueue.runningQueueState = RunningQueueState(
            enqueuedBucketCount: 1,
            enqueuedTests: [TestName(className: "class", methodName: "test")],
            dequeuedBucketCount: 2,
            dequeuedTests: [:]
        )
        
        container.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue, job: createJob(jobId: "jobId")))
        
        XCTAssertEqual(
            try multipleQueuesJobStateProvider.state(jobId: "jobId"),
            JobState(jobId: "jobId", queueState: QueueState.running(bucketQueue.runningQueueState))
        )
    }
    
    func test___job_state___for_deleted_job() {
        container.add(deletedJobQueues: [createJobQueue(job: createJob(jobId: "jobId"))])
        
        XCTAssertEqual(
            try multipleQueuesJobStateProvider.state(jobId: "jobId"),
            JobState(jobId: "jobId", queueState: QueueState.deleted)
        )
    }
    
    func test___job_state___for_non_existing_job___throws() {
        assertThrows {
            try multipleQueuesJobStateProvider.state(jobId: "jobId")
        }
    }
}

