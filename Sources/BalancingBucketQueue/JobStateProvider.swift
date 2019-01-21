import BucketQueue
import Foundation
import Models

public protocol JobStateProvider {
    func state(jobId: JobId) throws -> JobState
}
