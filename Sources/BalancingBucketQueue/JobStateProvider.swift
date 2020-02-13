import BucketQueue
import Foundation
import Models
import QueueModels

public protocol JobStateProvider {
    func state(jobId: JobId) throws -> JobState
    var ongoingJobIds: Set<JobId> { get }
}

public extension JobStateProvider {
    var allJobStates: [JobState] {
        return ongoingJobIds.compactMap { jobId in
            try? state(jobId: jobId)
        }
    }
}
