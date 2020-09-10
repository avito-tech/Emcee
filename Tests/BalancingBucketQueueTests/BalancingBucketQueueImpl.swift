import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import WorkerCapabilitiesModels

public final class BalancingBucketQueueImpl {
    private let bucketQueueFactory: BucketQueueFactory
    private let multipleQueuesContainer = MultipleQueuesContainer()
    
    public init(
        bucketQueueFactory: BucketQueueFactory
    ) {
        self.bucketQueueFactory = bucketQueueFactory
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
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        MultipleQueuesDequeueableBucketSource(multipleQueuesContainer: multipleQueuesContainer).dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
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
