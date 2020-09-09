import BucketQueue
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class BalancingBucketQueueImpl: BalancingBucketQueue {
    private let bucketQueueFactory: BucketQueueFactory
    private let nothingToDequeueBehavior: NothingToDequeueBehavior
    private let multipleQueuesContainer = MultipleQueuesContainer()
    
    public init(
        bucketQueueFactory: BucketQueueFactory,
        nothingToDequeueBehavior: NothingToDequeueBehavior
    ) {
        self.bucketQueueFactory = bucketQueueFactory
        self.nothingToDequeueBehavior = nothingToDequeueBehavior
    }
    
    public func delete(jobId: JobId) throws {
        try MultipleQueuesJobManipulator(multipleQueuesContainer: multipleQueuesContainer).delete(jobId: jobId)
    }
    
    public var ongoingJobIds: Set<JobId> {
        MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).ongoingJobIds
    }
    
    public var ongoingJobGroupIds: Set<JobGroupId> {
        MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).ongoingJobGroupIds
    }
    
    public func state(jobId: JobId) throws -> JobState {
        try MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).state(jobId: jobId)
    }
    
    public func results(jobId: JobId) throws -> JobResults {
        try MultipleQueuesJobResultsProvider(multipleQueuesContainer: multipleQueuesContainer).results(jobId: jobId)
    }
    
    public func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) throws {
        try MultipleQueuesEnqueueableBucketReceptor(bucketQueueFactory: bucketQueueFactory, multipleQueuesContainer: multipleQueuesContainer).enqueue(buckets: buckets, prioritizedJob: prioritizedJob)
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeueResult {
        MultipleQueuesDequeueableBucketSource(multipleQueuesContainer: multipleQueuesContainer, nothingToDequeueBehavior: nothingToDequeueBehavior).dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
    }
    
    public func accept(bucketId: BucketId, testingResult: TestingResult, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        try MultipleQueuesBucketResultAccepter(multipleQueuesContainer: multipleQueuesContainer).accept(bucketId: bucketId, testingResult: testingResult, workerId: workerId)
    }
    
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        MultipleQueuesStuckBucketsReenqueuer(multipleQueuesContainer: multipleQueuesContainer).reenqueueStuckBuckets()
    }

    public var runningQueueState: RunningQueueState {
        MultipleQueuesRunningQueueStateProvider(multipleQueuesContainer: multipleQueuesContainer).runningQueueState
    }
}
