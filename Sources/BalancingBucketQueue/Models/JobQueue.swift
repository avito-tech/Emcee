import BucketQueue
import Foundation
import QueueModels

public struct JobQueue: DefinesExecutionOrder {
    public let bucketQueue: BucketQueue
    public let job: Job
    public let jobGroup: JobGroup
    public let resultsCollector: ResultsCollector
    
    public init(
        bucketQueue: BucketQueue,
        job: Job,
        jobGroup: JobGroup,
        resultsCollector: ResultsCollector
    ) {
        self.bucketQueue = bucketQueue
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
