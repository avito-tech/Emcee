import Foundation
import Models

public protocol QueueClientDelegate: class {
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError)
    func queueClientQueueIsEmpty(_ sender: QueueClient)
    func queueClientWorkerHasBeenBlocked(_ sender: QueueClient)
    func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval)
    func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration)
    func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket)
    func queueClient(_ sender: QueueClient, serverDidAcceptBucketResult bucketId: String)
    func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient)
    func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: String)
}
