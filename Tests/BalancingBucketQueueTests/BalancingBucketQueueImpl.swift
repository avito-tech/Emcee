import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import DateProvider
import Foundation
import MetricsExtensions
import MetricsTestHelpers
import QueueModels
import WorkerCapabilitiesModels

public final class BalancingBucketQueueImpl {
    private let bucketQueueFactory: BucketQueueFactory
    private let dateProvider: DateProvider
    private let emceeVersion: Version
    private let multipleQueuesContainer = MultipleQueuesContainer()
    
    public init(
        bucketQueueFactory: BucketQueueFactory,
        dateProvider: DateProvider,
        emceeVersion: Version
    ) {
        self.bucketQueueFactory = bucketQueueFactory
        self.dateProvider = dateProvider
        self.emceeVersion = emceeVersion
    }
    
    public func delete(jobId: JobId) throws {
        try MultipleQueuesJobManipulator(
            dateProvider: dateProvider,
            specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider(),
            multipleQueuesContainer: multipleQueuesContainer,
            emceeVersion: emceeVersion
        ).delete(jobId: jobId)
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
