import BucketQueue
import Models
import QueueCommunication
import QueueModels

public final class WorkerPermissionAwareBalancingBucketQueue: BalancingBucketQueue {
    private let balancingBucketQueue: BalancingBucketQueue
    private let workerPermissionProvider: WorkerPermissionProvider
    private let nothingToDequeueBehavior: NothingToDequeueBehavior

    public init(
        workerPermissionProvider: WorkerPermissionProvider,
        balancingBucketQueue: BalancingBucketQueue,
        nothingToDequeueBehavior: NothingToDequeueBehavior
    ) {
        self.workerPermissionProvider = workerPermissionProvider
        self.balancingBucketQueue = balancingBucketQueue
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }

    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        guard workerPermissionProvider.utilizationPermissionForWorker(workerId: workerId) == .allowedToUtilize else {
            return nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults:[])
        }

        return balancingBucketQueue.dequeueBucket(requestId: requestId, workerId: workerId)
    }

    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return balancingBucketQueue.previouslyDequeuedBucket(requestId: requestId, workerId: workerId)
    }

    public func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        return try balancingBucketQueue.accept(testingResult: testingResult, requestId: requestId, workerId: workerId)
    }

    public func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        balancingBucketQueue.enqueue(buckets: buckets, prioritizedJob: prioritizedJob)
    }

    public func delete(jobId: JobId) throws {
        try balancingBucketQueue.delete(jobId: jobId)
    }

    public func results(jobId: JobId) throws -> JobResults {
        try balancingBucketQueue.results(jobId: jobId)
    }

    public func state(jobId: JobId) throws -> JobState {
        try balancingBucketQueue.state(jobId: jobId)
    }

    public var ongoingJobIds: Set<JobId> {
        balancingBucketQueue.ongoingJobIds
    }

    public var runningQueueState: RunningQueueState {
        balancingBucketQueue.runningQueueState
    }

    public func reenqueueStuckBuckets() -> [StuckBucket] {
        balancingBucketQueue.reenqueueStuckBuckets()
    }
}
