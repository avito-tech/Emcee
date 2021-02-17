import BucketQueue
import Foundation
import MetricsExtensions
import QueueModels

public struct JobQueue: DefinesExecutionOrder {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let bucketQueue: BucketQueue
    public let job: Job
    public let jobGroup: JobGroup
    public let resultsCollector: ResultsCollector
    public let persistentMetricsJobId: String
    
    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketQueue: BucketQueue,
        job: Job,
        jobGroup: JobGroup,
        resultsCollector: ResultsCollector,
        persistentMetricsJobId: String
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.bucketQueue = bucketQueue
        self.job = job
        self.jobGroup = jobGroup
        self.resultsCollector = resultsCollector
        self.persistentMetricsJobId = persistentMetricsJobId
    }
    
    public func executionOrder(relativeTo other: JobQueue) -> ExecutionOrder {
        guard jobGroup == other.jobGroup else {
            return jobGroup.executionOrder(relativeTo: other.jobGroup)
        }
        return job.executionOrder(relativeTo: other.job)
    }
}
