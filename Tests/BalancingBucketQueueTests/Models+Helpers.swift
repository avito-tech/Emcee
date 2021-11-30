import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import MetricsExtensions
import Foundation
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
    bucketQueueHolder: BucketQueueHolder = BucketQueueHolder(),
    job: Job = createJob(),
    jobGroup: JobGroup = createJobGroup(),
    resultsCollector: ResultsCollector = ResultsCollector()
) -> JobQueue {
    JobQueue(
        analyticsConfiguration: AnalyticsConfiguration(),
        bucketQueueHolder: bucketQueueHolder,
        job: job,
        jobGroup: jobGroup,
        resultsCollector: resultsCollector
    )
}
