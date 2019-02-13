import BucketQueue
import Foundation
import Models
import ResultsCollector

final class JobQueue: Comparable {
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
    
    static func < (left: JobQueue, right: JobQueue) -> Bool {
        if left.prioritizedJob == right.prioritizedJob {
            return left.creationTime < right.creationTime
        }
        return left.prioritizedJob < right.prioritizedJob
    }
    
    static func == (left: JobQueue, right: JobQueue) -> Bool {
        return left.prioritizedJob == right.prioritizedJob
            && left.creationTime == right.creationTime
    }
}
