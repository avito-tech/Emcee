import BucketQueue
import Foundation
import Models

/// Balancing bucket queue is a wrapper on top of multiple BucketQueue objects - each wrapped by JobQueue instance.
/// It will provide buckets for dequeueing by querying all jobs.
public protocol BalancingBucketQueue {
    /// Removes job.
    func delete(jobId: JobId)
    
    /// Returns a state for given job.
    func state(jobId: JobId) throws -> BucketQueueState
    
    /// Returns collected results for given job.
    func results(jobId: JobId) throws -> [TestingResult]
    
    /// Enqueues buckets to a given job. If job does not exist, will create a new job with given id.
    func enqueue(buckets: [Bucket], jobId: JobId)
    
    /// Dequeues first available bucket from job that has buckets to dequeue.
    func dequeueBucket(requestId: String, workerId: String) -> DequeueResult
    
    /// Accepts previously dequeued bucket.
    func accept(testingResult: TestingResult, requestId: String, workerId: String) throws -> BucketQueueAcceptResult
    
    /// Returns stuck buckets for all jobs.
    func reenqueueStuckBuckets() -> [StuckBucket]
}
