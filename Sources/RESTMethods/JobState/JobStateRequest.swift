import Foundation
import Models

public final class JobStateRequest: Codable {
    public let jobId: JobId

    public init(jobId: JobId) {
        self.jobId = jobId
    }
}
