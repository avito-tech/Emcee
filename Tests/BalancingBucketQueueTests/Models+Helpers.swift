import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import Foundation
import Models
import QueueModels

func createJob(
    creationTime: Date = Date(timeIntervalSince1970: 100),
    jobId: JobId = "jobId",
    priority: Priority = .medium
) -> Job {
    Job(
        creationTime: creationTime,
        jobId: jobId,
        priority: priority
    )
}

func createJobGroup(
    creationTime: Date = Date(timeIntervalSince1970: 100),
    jobGroupId: JobGroupId = "jobGroupId",
    priority: Priority = .medium
) -> JobGroup {
    JobGroup(
        creationTime: creationTime,
        jobGroupId: jobGroupId,
        priority: priority
    )
}

func createJobQueue(
    bucketQueue: BucketQueue = FakeBucketQueue(),
    job: Job = createJob(),
    jobGroup: JobGroup = createJobGroup(),
    resultsCollector: ResultsCollector = ResultsCollector()
) -> JobQueue {
    JobQueue(
        bucketQueue: bucketQueue,
        job: job,
        jobGroup: jobGroup,
        resultsCollector: resultsCollector
    )
}
