import Foundation
import Models
import QueueClient

class FakeQueueClientDelegate: QueueClientDelegate {
    
    enum ServerResponse {
        case error(QueueClientError)
        case queueIsEmpty
        case checkAfter(TimeInterval)
        case workerConfiguration(WorkerConfiguration)
        case bucket(Bucket)
        case acceptedBucketResult(String)
        case workerHasBeenBlocked
        case alivenessAccepted
        case queueServerVersion(String)
    }
    
    var responses = [ServerResponse]()
    
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        responses.append(ServerResponse.error(error))
    }
    
    func queueClientQueueIsEmpty(_ sender: QueueClient) {
        responses.append(ServerResponse.queueIsEmpty)
    }
    
    func queueClientWorkerHasBeenBlocked(_ sender: QueueClient) {
        responses.append(ServerResponse.workerHasBeenBlocked)
    }
    
    func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval) {
        responses.append(ServerResponse.checkAfter(after))
    }
    
    func queueClient(_ sender: QueueClient, didReceiveWorkerConfiguration workerConfiguration: WorkerConfiguration) {
        responses.append(ServerResponse.workerConfiguration(workerConfiguration))
    }
    
    func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket) {
        responses.append(ServerResponse.bucket(bucket))
    }
    
    func queueClient(_ sender: QueueClient, serverDidAcceptBucketResult bucketId: String) {
        responses.append(ServerResponse.acceptedBucketResult(bucketId))
    }
    
    func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: String) {
        responses.append(ServerResponse.queueServerVersion(version))
    }
    
    func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient) {
        responses.append(ServerResponse.alivenessAccepted)
    }
}
