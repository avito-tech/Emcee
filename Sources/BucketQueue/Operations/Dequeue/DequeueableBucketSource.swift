import BucketQueueModels
import QueueModels
import WorkerCapabilitiesModels

public protocol DequeueableBucketSource {
    
    /// Dequeues the next bucket for the provided worker id with provided worker capabilities.
    /// - Parameters:
    ///     - workerCapabilities: Capabilities of the worker with given `workerId`. Queue analyzes them and dequeues buckets which requirements satisfy the provided capabilities.
    ///     - workerId: Worker which is dequeueing bucket. Queue may decide to not provide bucket for any reason (e.g. if worker has already executed tests in bucket before)
    /// - Returns: `nil` if queue does not contain any buckets suitable to be ran on the given `workerId` or if `workerCapabilities` do not satisfy any buckets in the queue.
    func dequeueBucket(
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId
    ) -> DequeuedBucket?
}
