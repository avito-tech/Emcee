import Foundation
import QueueModels

public protocol QueueClientDelegate: class {
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError)
    func queueClientQueueIsEmpty(_ sender: QueueClient)
    func queueClientWorkerNotRegistered(_ sender: QueueClient)
    func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval)
    func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket)
    func queueClientDidScheduleTests(_ sender: QueueClient, requestId: RequestId)
    func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState)
    func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults)
    func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId)
}
