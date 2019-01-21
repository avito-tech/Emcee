import Foundation
import Models

public final class JobResultsRequest: Codable {
    public let jobId: JobId
    
    public init(jobId: JobId) {
        self.jobId = jobId
    }
}
