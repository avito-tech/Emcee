import BucketQueue
import Foundation
import Models
import ResultsCollector

final class JobQueue: Comparable {
    public let jobId: JobId
    public let creationTime: Date
    public let bucketQueue: BucketQueue
    public let resultsCollector: ResultsCollector

    public init(
        jobId: JobId,
        creationTime: Date,
        bucketQueue: BucketQueue,
        resultsCollector: ResultsCollector)
    {
        self.jobId = jobId
        self.creationTime = creationTime
        self.bucketQueue = bucketQueue
        self.resultsCollector = resultsCollector
    }
    
    static func < (left: JobQueue, right: JobQueue) -> Bool {
        return left.creationTime < right.creationTime
    }
    
    static func == (left: JobQueue, right: JobQueue) -> Bool {
        return left.jobId == right.jobId
    }
}
