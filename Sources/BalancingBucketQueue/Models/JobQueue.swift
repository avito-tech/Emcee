import BucketQueue
import Foundation
import MetricsExtensions
import QueueModels

public struct JobQueue: DefinesExecutionOrder {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let bucketQueueHolder: BucketQueueHolder
    public let job: Job
    public let jobGroup: JobGroup
    public let resultsCollector: ResultsCollector
    
    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketQueueHolder: BucketQueueHolder,
        job: Job,
        jobGroup: JobGroup,
        resultsCollector: ResultsCollector
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.bucketQueueHolder = bucketQueueHolder
        self.job = job
        self.jobGroup = jobGroup
        self.resultsCollector = resultsCollector
    }
    
    public func executionOrder(relativeTo other: JobQueue) -> ExecutionOrder {
        guard jobGroup == other.jobGroup else {
            return jobGroup.executionOrder(relativeTo: other.jobGroup)
        }
        return job.executionOrder(relativeTo: other.job)
    }
}
