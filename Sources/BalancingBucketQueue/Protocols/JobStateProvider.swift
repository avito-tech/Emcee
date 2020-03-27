import BucketQueue
import QueueModels

public protocol JobStateProvider {
    func state(jobId: JobId) throws -> JobState
    var ongoingJobIds: Set<JobId> { get }
    var ongoingJobGroupIds: Set<JobGroupId> { get }
}

public extension JobStateProvider {
    var allJobStates: [JobState] {
        return ongoingJobIds.compactMap { jobId in
            try? state(jobId: jobId)
        }
    }
}
