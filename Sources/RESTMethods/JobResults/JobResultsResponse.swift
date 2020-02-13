import Foundation
import QueueModels

public final class JobResultsResponse: Codable {
    public let jobResults: JobResults

    public init(jobResults: JobResults) {
        self.jobResults = jobResults
    }
}
