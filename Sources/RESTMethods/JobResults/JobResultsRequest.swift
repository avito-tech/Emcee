import Foundation
import QueueModels

public final class JobResultsRequest: Codable {
    public let jobId: JobId
    
    public init(jobId: JobId) {
        self.jobId = jobId
    }
}
