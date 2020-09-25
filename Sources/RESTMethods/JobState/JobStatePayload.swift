import Foundation
import QueueModels

public final class JobStatePayload: Codable {
    public let jobId: JobId

    public init(jobId: JobId) {
        self.jobId = jobId
    }
}
