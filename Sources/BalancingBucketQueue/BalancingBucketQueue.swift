import BucketQueue
import Foundation
import Models

/// Balancing bucket queue is a wrapper on top of multiple BucketQueue objects - each wrapped by JobQueue instance.
/// It will provide buckets for dequeueing by querying all jobs.
public protocol BalancingBucketQueue:
    BucketResultAccepter,
    DequeueableBucketSource,
    EnqueueableBucketReceptor,
    QueueStateProvider,
    StuckBucketsReenqueuer
{
    /// Removes job.
    func delete(jobId: JobId)
    
    /// Returns a state for given job.
    func state(jobId: JobId) throws -> BucketQueueState
    
    /// Returns collected results for given job.
    func results(jobId: JobId) throws -> [TestingResult]
}
