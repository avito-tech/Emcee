import Foundation
import Models
import Version

public protocol QueueClientDelegate: class {
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError)
    func queueClientQueueIsEmpty(_ sender: QueueClient)
    func queueClientWorkerConsideredNotAlive(_ sender: QueueClient)
    func queueClientWorkerHasBeenBlocked(_ sender: QueueClient)
    func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval)
    func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration)
    func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket)
    func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient)
    func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: Version)
    func queueClientDidScheduleTests(_ sender: QueueClient, requestId: RequestId)
    func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState)
    func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults)
    func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId)
}
