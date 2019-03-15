import Foundation
import Models
import QueueClient
import Version

class FakeQueueClientDelegate: QueueClientDelegate {
    enum ServerResponse {
        case error(QueueClientError)
        case queueIsEmpty
        case checkAfter(TimeInterval)
        case workerConfiguration(WorkerConfiguration)
        case bucket(Bucket)
        case acceptedBucketResult(String)
        case workerHasBeenBlocked
        case workerConsideredNotAlive
        case alivenessAccepted
        case queueServerVersion(Version)
        case didScheduleTests(String)
        case fetchedJobState(JobState)
        case fecthedJobResults(JobResults)
        case deletedJob(JobId)
    }
    
    var responses = [ServerResponse]()
    
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        responses.append(ServerResponse.error(error))
    }
    
    func queueClientQueueIsEmpty(_ sender: QueueClient) {
        responses.append(ServerResponse.queueIsEmpty)
    }
    
    func queueClientWorkerConsideredNotAlive(_ sender: QueueClient) {
        responses.append(ServerResponse.workerConsideredNotAlive)
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
    
    func queueClient(_ sender: QueueClient, didFetchQueueServerVersion version: Version) {
        responses.append(ServerResponse.queueServerVersion(version))
    }
    
    func queueClientWorkerHasBeenIndicatedAsAlive(_ sender: QueueClient) {
        responses.append(ServerResponse.alivenessAccepted)
    }
    
    func queueClientDidScheduleTests(_ sender: QueueClient, requestId: String) {
        responses.append(ServerResponse.didScheduleTests(requestId))
    }
    
    func queueClient(_ sender: QueueClient, didFetchJobState jobState: JobState) {
        responses.append(ServerResponse.fetchedJobState(jobState))
    }
    
    func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults) {
        responses.append(ServerResponse.fecthedJobResults(jobResults))
    }
    
    func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId) {
        responses.append(ServerResponse.deletedJob(jobId))
    }
}
