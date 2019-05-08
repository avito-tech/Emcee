import Basic
import BucketQueue
import DateProvider
import Dispatch
import Foundation
import Logging
import Models
import ResultsCollector

final class BalancingBucketQueueImpl: BalancingBucketQueue {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.BalancingBucketQueueImpl.syncQueue")
    private var bucketQueues: SortedArray<JobQueue>
    private let bucketQueueFactory: BucketQueueFactory
    private let nothingToDequeueBehavior: NothingToDequeueBehavior
    
    public init(
        bucketQueueFactory: BucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehavior)
    {
        self.bucketQueues = BalancingBucketQueueImpl.createQueues(contents: [])
        self.bucketQueueFactory = bucketQueueFactory
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }
    
    private static func createQueues(contents: [JobQueue]) -> SortedArray<JobQueue> {
        return SortedArray(contents) { leftQueue, rightQueue -> Bool in
            leftQueue.hasPreeminence(overJobQueue: rightQueue)
        }
    }
    
    func delete(jobId: JobId) throws {
        return try syncQueue.sync {
            let newContents = bucketQueues.values.filter { $0.prioritizedJob.jobId != jobId }
            guard newContents.count < bucketQueues.count else {
                throw BalancingBucketQueueError.noQueue(jobId: jobId)
            }
            bucketQueues = BalancingBucketQueueImpl.createQueues(contents: newContents)
        }
    }
    
    var ongoingJobIds: Set<JobId> {
        let jobIds = syncQueue.sync {
            bucketQueues.map { $0.prioritizedJob.jobId }
        }
        return Set(jobIds)
    }
    
    func state(jobId: JobId) throws -> JobState {
        return try syncQueue.sync {
            guard let existingJobQueue = jobQueue__onSyncQueue(jobId: jobId) else {
                throw BalancingBucketQueueError.noQueue(jobId: jobId)
            }
            return JobState(jobId: jobId, queueState: existingJobQueue.bucketQueue.state)
        }
    }
    
    func results(jobId: JobId) throws -> JobResults {
        return try syncQueue.sync {
            guard let existingJobQueue = jobQueue__onSyncQueue(jobId: jobId) else {
                throw BalancingBucketQueueError.noQueue(jobId: jobId)
            }
            return JobResults(jobId: jobId, testingResults: existingJobQueue.resultsCollector.collectedResults)
        }
    }
    
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        syncQueue.sync {
            let bucketQueue: BucketQueue
            if let existingJobQueue = jobQueue__onSyncQueue(jobId: prioritizedJob.jobId) {
                bucketQueue = existingJobQueue.bucketQueue
            } else {
                bucketQueue = bucketQueueFactory.createBucketQueue()
                add_onSyncQueue(bucketQueue: bucketQueue, prioritizedJob: prioritizedJob)
            }
            bucketQueue.enqueue(buckets: buckets)
        }
    }
    
    func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket? {
        return syncQueue.sync {
            let bucketQueues = bucketQueues_onSyncQueue()
            
            return bucketQueues
                .compactMap({ $0.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) })
                .first
        }
    }
    
    func dequeueBucket(requestId: String, workerId: String) -> DequeueResult {
        return syncQueue.sync {
            let bucketQueues = bucketQueues_onSyncQueue()
            
            if let previouslyDequeuedBucket = bucketQueues
                .compactMap({ $0.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) })
                .first {
                return .dequeuedBucket(previouslyDequeuedBucket)
            }
            
            var dequeueResults = [DequeueResult]()
            for queue in bucketQueues {
                let dequeueResult = queue.dequeueBucket(requestId: requestId, workerId: workerId)
                switch dequeueResult {
                case .dequeuedBucket:
                    return dequeueResult
                case .queueIsEmpty, .checkAgainLater, .workerIsNotAlive, .workerIsBlocked:
                    dequeueResults.append(dequeueResult)
                }
            }
            
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: dequeueResults)
        }
    }
    
    func accept(testingResult: TestingResult, requestId: String, workerId: String) throws -> BucketQueueAcceptResult {
        return try syncQueue.sync {
            if let appropriateJobQueue: JobQueue = bucketQueues
                .filter({ jobQueue in
                    jobQueue.bucketQueue.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) != nil
                })
                .first
            {
                let result = try appropriateJobQueue.bucketQueue.accept(
                    testingResult: testingResult,
                    requestId: requestId,
                    workerId: workerId
                )
                appropriateJobQueue.resultsCollector.append(testingResult: result.testingResultToCollect)
                return result
            }
            
            throw BalancingBucketQueueError.noMatchingQueueFound(
                testingResult: testingResult,
                requestId: requestId,
                workerId: workerId
            )
        }
    }
    
    func reenqueueStuckBuckets() -> [StuckBucket] {
        let bucketQueues = syncQueue.sync { self.bucketQueues }
        return bucketQueues.flatMap { jobQueue -> [StuckBucket] in
            jobQueue.bucketQueue.reenqueueStuckBuckets()
        }
    }
    
    var state: QueueState {
        return syncQueue.sync {
            let states = bucketQueues_onSyncQueue().map { $0.state }
            return QueueState(
                enqueuedBucketCount: states.map { $0.enqueuedBucketCount }.reduce(0, +),
                dequeuedBucketCount: states.map { $0.dequeuedBucketCount }.reduce(0, +)
            )
        }
    }
    
    private func jobQueue__onSyncQueue(jobId: JobId) -> JobQueue? {
        return bucketQueues.first(where: { jobQueue -> Bool in jobQueue.prioritizedJob.jobId == jobId })
    }
    
    private func add_onSyncQueue(bucketQueue: BucketQueue, prioritizedJob: PrioritizedJob) {
        bucketQueues.insert(
            JobQueue(
                prioritizedJob: prioritizedJob,
                creationTime: Date(),
                bucketQueue: bucketQueue,
                resultsCollector: ResultsCollector()
            )
        )
    }
    
    private func bucketQueues_onSyncQueue() -> [BucketQueue] {
        return bucketQueues.map { $0.bucketQueue }
    }
}
