import Foundation
import Models

public protocol JobResultsProvider {
    func results(jobId: JobId) throws -> JobResults
}
