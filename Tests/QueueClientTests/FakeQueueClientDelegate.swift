import Foundation
import QueueClient
import QueueModels

class FakeQueueClientDelegate: QueueClientDelegate {
    enum ServerResponse {
        case error(QueueClientError)
        case fetchedJobState(JobState)
        case fecthedJobResults(JobResults)
        case deletedJob(JobId)
    }
    
    var responses = [ServerResponse]()
    
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError) {
        responses.append(ServerResponse.error(error))
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
