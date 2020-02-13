import BucketQueue
import Foundation
import Models
import QueueModels
import ResultsCollector

final class JobQueue {
    public let prioritizedJob: PrioritizedJob
    public let creationTime: Date
    public let bucketQueue: BucketQueue
    public let resultsCollector: ResultsCollector

    public init(
        prioritizedJob: PrioritizedJob,
        creationTime: Date,
        bucketQueue: BucketQueue,
        resultsCollector: ResultsCollector)
    {
        self.prioritizedJob = prioritizedJob
        self.creationTime = creationTime
        self.bucketQueue = bucketQueue
        self.resultsCollector = resultsCollector
    }
    
    /// When A > B it means A has preeminence over B in terms of priority of test invocation
    /// So when A < B < C, C has preeminence over B and A, and B has preeminence over A.
    /// To keep this semantic cleaner we don't use Comparable, we expose this method.
    func hasPreeminence(overJobQueue otherJobQueue: JobQueue) -> Bool {
        let otherJobQueue = otherJobQueue
        if otherJobQueue.prioritizedJob.priority == self.prioritizedJob.priority {
            return otherJobQueue.creationTime > self.creationTime
        }
        return otherJobQueue.prioritizedJob.priority < self.prioritizedJob.priority
    }
}
