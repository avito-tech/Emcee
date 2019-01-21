import Foundation
import Models

public final class JobResultsResponse: Codable {
    public let jobResults: JobResults

    public init(jobResults: JobResults) {
        self.jobResults = jobResults
    }
}
