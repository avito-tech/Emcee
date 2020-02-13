import Foundation
import Models
import QueueModels

public protocol JobResultsProvider {
    func results(jobId: JobId) throws -> JobResults
}
