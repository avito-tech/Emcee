import Foundation
import Models

public final class JobDeleteRequest: Codable {
    public let jobId: JobId
    
    public init(jobId: JobId) {
        self.jobId = jobId
    }
}

