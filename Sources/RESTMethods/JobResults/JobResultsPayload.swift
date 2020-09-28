import Foundation
import QueueModels

public final class JobResultsPayload: Codable {
    public let jobId: JobId
    
    public init(jobId: JobId) {
        self.jobId = jobId
    }
}
