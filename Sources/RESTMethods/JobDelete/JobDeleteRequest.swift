import Foundation
import QueueModels

public final class JobDeleteRequest: Codable {
    public let jobId: JobId
    
    public init(jobId: JobId) {
        self.jobId = jobId
    }
}

