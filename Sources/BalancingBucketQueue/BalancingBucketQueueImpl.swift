import BucketQueue
import Foundation
import QueueModels

final class BalancingBucketQueueImpl: BalancingBucketQueue {
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
    
    func delete(jobId: JobId) throws {
        try MultipleQueuesJobManipulator(multipleQueuesContainer: multipleQueuesContainer).delete(jobId: jobId)
    }
    
    var ongoingJobIds: Set<JobId> {
        MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).ongoingJobIds
    }
    
    var ongoingJobGroupIds: Set<JobGroupId> {
        MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).ongoingJobGroupIds
    }
    
    func state(jobId: JobId) throws -> JobState {
        try MultipleQueuesJobStateProvider(multipleQueuesContainer: multipleQueuesContainer).state(jobId: jobId)
    }
    
    func results(jobId: JobId) throws -> JobResults {
        try MultipleQueuesJobResultsProvider(multipleQueuesContainer: multipleQueuesContainer).results(jobId: jobId)
    }
    
    func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) {
        MultipleQueuesEnqueueableBucketReceptor(bucketQueueFactory: bucketQueueFactory, multipleQueuesContainer: multipleQueuesContainer).enqueue(buckets: buckets, prioritizedJob: prioritizedJob)
    }
    
    func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        MultipleQueuesDequeueableBucketSource(multipleQueuesContainer: multipleQueuesContainer, nothingToDequeueBehavior: nothingToDequeueBehavior).previouslyDequeuedBucket(requestId: requestId, workerId: workerId)
    }
    
    func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        MultipleQueuesDequeueableBucketSource(multipleQueuesContainer: multipleQueuesContainer, nothingToDequeueBehavior: nothingToDequeueBehavior).dequeueBucket(requestId: requestId, workerId: workerId)
    }
    
    func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult {
        try MultipleQueuesBucketResultAccepter(multipleQueuesContainer: multipleQueuesContainer).accept(testingResult: testingResult, requestId: requestId, workerId: workerId)
    }
    
    func reenqueueStuckBuckets() -> [StuckBucket] {
        MultipleQueuesStuckBucketsReenqueuer(multipleQueuesContainer: multipleQueuesContainer).reenqueueStuckBuckets()
    }

    var runningQueueState: RunningQueueState {
        MultipleQueuesRunningQueueStateProvider(multipleQueuesContainer: multipleQueuesContainer).runningQueueState
    }
}
