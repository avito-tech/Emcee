import BucketQueue
import CountedSet
import DateProvider
import Dispatch
import Foundation
import Logging
import Models
import QueueModels

final class BalancingBucketQueueImpl: BalancingBucketQueue {
    private let syncQueue = DispatchQueue(label: "BalancingBucketQueueImpl.syncQueue")
    private let bucketQueueFactory: BucketQueueFactory
    private let nothingToDequeueBehavior: NothingToDequeueBehavior
    
    private var runningJobGroups_onSyncQueue = CountedSet<JobGroup>()
    private var runningJobQueues_onSyncQueue = [JobQueue]()
    private var deletedJobQueues_onSyncQueue = [JobQueue]()
    
    public init(
        bucketQueueFactory: BucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehavior
    ) {
        self.bucketQueueFactory = bucketQueueFactory
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }
    
    func delete(jobId: JobId) throws {
        return try syncQueue.sync {
            let jobQueuesToDelete = runningJobQueues_onSyncQueue.filter { $0.job.jobId == jobId }
            guard !jobQueuesToDelete.isEmpty else {
                throw BalancingBucketQueueError.noQueue(jobId: jobId)
            }
            for jobQueue in jobQueuesToDelete {
                jobQueue.bucketQueue.removeAllEnqueuedBuckets()
            }
            deletedJobQueues_onSyncQueue.append(contentsOf: jobQueuesToDelete)
            runningJobQueues_onSyncQueue.removeAll(where: { $0.job.jobId == jobId })
            deleteJobGroupsThatNoLongerPresent_onSyncQueue(deletedJobQueues: jobQueuesToDelete)
        }
    }
    
    var ongoingJobIds: Set<JobId> {
        let jobIds = syncQueue.sync {
            runningJobQueues_onSyncQueue.map { $0.job.jobId }
        }
        return Set(jobIds)
    }
    
    var ongoingJobGroupIds: Set<JobGroupId> {
        return syncQueue.sync { Set(runningJobGroups_onSyncQueue.map { $0.jobGroupId }) }
    }
    
    func state(jobId: JobId) throws -> JobState {
        return try syncQueue.sync {
            if let existingJobQueue = runningJobQueue_onSyncQueue(jobId: jobId) {
                return JobState(
                    jobId: existingJobQueue.job.jobId,
                    queueState: QueueState.running(existingJobQueue.bucketQueue.runningQueueState)
                )
            }
            
            if let deletedJobQueue = deletedJobQueue_onSyncQueue(jobId: jobId) {
                return JobState(
                    jobId: deletedJobQueue.job.jobId,
                    queueState: QueueState.deleted
                )
            }
            
            throw BalancingBucketQueueError.noQueue(jobId: jobId)
        }
    }
    
    func results(jobId: JobId) throws -> JobResults {
        return try syncQueue.sync {
            if let existingJobQueue = runningJobQueue_onSyncQueue(jobId: jobId) {
                return JobResults(jobId: jobId, testingResults: existingJobQueue.resultsCollector.collectedResults)
            }
            if let deletedJobQueue = deletedJobQueue_onSyncQueue(jobId: jobId) {
                return JobResults(jobId: jobId, testingResults: deletedJobQueue.resultsCollector.collectedResults)
            }
            throw BalancingBucketQueueError.noQueue(jobId: jobId)
        }
    }
    
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        syncQueue.sync {
            let bucketQueue: BucketQueue
            if let existingJobQueue = runningJobQueue_onSyncQueue(jobId: prioritizedJob.jobId) {
                bucketQueue = existingJobQueue.bucketQueue
            } else if let previouslyDeletedJobQueue = deletedJobQueue_onSyncQueue(jobId: prioritizedJob.jobId) {
                bucketQueue = previouslyDeletedJobQueue.bucketQueue
                bucketQueue.removeAllEnqueuedBuckets()
                addJobQueue_onSyncQueue(jobQueue: previouslyDeletedJobQueue)
            } else {
                bucketQueue = bucketQueueFactory.createBucketQueue()
                addNewBucketQueue_onSyncQueue(bucketQueue: bucketQueue, prioritizedJob: prioritizedJob)
            }
            bucketQueue.enqueue(buckets: buckets)
        }
    }
    
    func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return syncQueue.sync {
            return runningJobQueues_onSyncQueue
                .map { $0.bucketQueue }
                .compactMap({ $0.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) })
                .first
        }
    }
    
    func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        return syncQueue.sync {
            let bucketQueues = runningJobQueues_onSyncQueue.map { $0.bucketQueue }
            
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
                case .workerIsNotAlive:
                    return .workerIsNotAlive
                case .queueIsEmpty, .checkAgainLater:
                    dequeueResults.append(dequeueResult)
                }
            }
            
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: dequeueResults)
        }
    }
    
    func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        return try syncQueue.sync {
            if let appropriateJobQueue: JobQueue = allJobQueues_onSyncQueue
                .filter({ jobQueue in
                    jobQueue.bucketQueue.previouslyDequeuedBucket(requestId: requestId, workerId: workerId) != nil
                })
                .first
            {
                Logger.debug("Found corresponding job queue for \(requestId) \(workerId)")
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
        let bucketQueues = syncQueue.sync { runningJobQueues_onSyncQueue }
        return bucketQueues.flatMap { jobQueue -> [StuckBucket] in
            jobQueue.bucketQueue.reenqueueStuckBuckets()
        }
    }

    var runningQueueState: RunningQueueState {
        return syncQueue.sync {
            let states = runningJobQueues_onSyncQueue.map { $0.bucketQueue.runningQueueState }
            var dequeuedTests = MapWithCollection<WorkerId, TestName>()
            for state in states {
                dequeuedTests.extend(state.dequeuedTests)
            }
            
            return RunningQueueState(
                enqueuedTests: states.flatMap { $0.enqueuedTests },
                dequeuedTests: dequeuedTests
            )
        }
    }
    
    // MARK: - Internals
    
    private var allJobQueues_onSyncQueue: [JobQueue] {
        return runningJobQueues_onSyncQueue + deletedJobQueues_onSyncQueue
    }

    private func runningJobQueue_onSyncQueue(jobId: JobId) -> JobQueue? {
        return runningJobQueues_onSyncQueue.first(where: { jobQueue -> Bool in jobQueue.job.jobId == jobId })
    }
    
    private func deletedJobQueue_onSyncQueue(jobId: JobId) -> JobQueue? {
        return deletedJobQueues_onSyncQueue.first(where: { jobQueue -> Bool in jobQueue.job.jobId == jobId })
    }
    
    // MARK: Adding new jobs
    
    private func addNewBucketQueue_onSyncQueue(bucketQueue: BucketQueue, prioritizedJob: PrioritizedJob) {
        addJobQueue_onSyncQueue(
            jobQueue: JobQueue(
                bucketQueue: bucketQueue,
                job: Job(creationTime: Date(), jobId: prioritizedJob.jobId, priority: prioritizedJob.jobPriority),
                jobGroup: fetchOrCreateJobGroup_onSyncQueue(
                    jobGroupId: prioritizedJob.jobGroupId,
                    jobGroupPriority: prioritizedJob.jobGroupPriority
                ),
                resultsCollector: ResultsCollector()
            )
        )
    }

    private func addJobQueue_onSyncQueue(jobQueue: JobQueue) {
        runningJobQueues_onSyncQueue.append(jobQueue)
        runningJobQueues_onSyncQueue.sort { $0.executionOrder(relativeTo: $1) == .before }
        deletedJobQueues_onSyncQueue.removeAll(where: { $0.job.jobId == jobQueue.job.jobId })
    }
    
    // MARK: Managing Job Groups
    
    private func fetchOrCreateJobGroup_onSyncQueue(jobGroupId: JobGroupId, jobGroupPriority: Priority) -> JobGroup {
        let matchingJobGroups = runningJobGroups_onSyncQueue.filter { $0.jobGroupId == jobGroupId && $0.priority == jobGroupPriority }
        if let matchingJobGroup = matchingJobGroups.first {
            runningJobGroups_onSyncQueue.update(with: matchingJobGroup)
            return matchingJobGroup
        }
        let jobGroup = JobGroup(
            creationTime: Date(),
            jobGroupId: jobGroupId,
            priority: jobGroupPriority
        )
        runningJobGroups_onSyncQueue.update(with: jobGroup)
        return jobGroup
    }
    
    private func deleteJobGroupsThatNoLongerPresent_onSyncQueue(deletedJobQueues: [JobQueue]) {
        for deletedJobQueue in deletedJobQueues {
            runningJobGroups_onSyncQueue.remove(deletedJobQueue.jobGroup)
        }
    }
}
