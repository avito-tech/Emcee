import Foundation
import QueueModels

public protocol QueueClientDelegate: class {
    func queueClient(_ sender: QueueClient, didFailWithError error: QueueClientError)
    func queueClient(_ sender: QueueClient, didFetchJobResults jobResults: JobResults)
    func queueClient(_ sender: QueueClient, didDeleteJob jobId: JobId)
}
