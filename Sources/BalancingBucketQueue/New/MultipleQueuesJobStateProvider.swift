import Foundation
import QueueModels

public final class MultipleQueuesJobStateProvider: JobStateProvider {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public var ongoingJobGroupIds: Set<JobGroupId> {
        Set(multipleQueuesContainer.trackedJobGroups().map { $0.jobGroupId })
    }
    
    public var ongoingJobIds: Set<JobId> {
        Set(multipleQueuesContainer.allRunningJobQueues().map { $0.job.jobId })
    }
    
    public func state(jobId: JobId) throws -> JobState {
        if let jobQueue = multipleQueuesContainer.allRunningJobQueues().first(where: { $0.job.jobId == jobId }) {
            return JobState(
                jobId: jobId,
                queueState: QueueState.running(jobQueue.bucketQueue.runningQueueState)
            )
        }
        
        if multipleQueuesContainer.allDeletedJobQueues().first(where: { $0.job.jobId == jobId }) != nil {
            return JobState(
                jobId: jobId,
                queueState: QueueState.deleted
            )
        }
        
        throw NoQueueForJobIdFoundError.noQueue(jobId: jobId)
    }
}
