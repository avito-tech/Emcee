import Foundation
import Models
import QueueClient
import QueueModels
import Models

class FakeQueueClientDelegate: QueueClientDelegate {
    enum ServerResponse {
        case error(QueueClientError)
        case queueIsEmpty
        case checkAfter(TimeInterval)
        case bucket(Bucket)
        case workerNotRegistered
        case didScheduleTests(RequestId)
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
    
    func queueClientWorkerNotRegistered(_ sender: QueueClient) {
        responses.append(ServerResponse.workerNotRegistered)
    }
    
    func queueClient(_ sender: QueueClient, fetchBucketLaterAfter after: TimeInterval) {
        responses.append(ServerResponse.checkAfter(after))
    }
    
    func queueClient(_ sender: QueueClient, didFetchBucket bucket: Bucket) {
        responses.append(ServerResponse.bucket(bucket))
    }
    
    func queueClientDidScheduleTests(_ sender: QueueClient, requestId: RequestId) {
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
