import Foundation
import QueueModels

public final class MultipleQueuesJobResultsProvider: JobResultsProvider {
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(multipleQueuesContainer: MultipleQueuesContainer) {
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func results(jobId: JobId) throws -> JobResults {
        try multipleQueuesContainer.performWithExclusiveAccess {
            
            if let jobQueue = multipleQueuesContainer.runningAndDeletedJobQueues().first(where: { jobQueue in jobQueue.job.jobId == jobId }) {
                return JobResults(jobId: jobId, testingResults: jobQueue.resultsCollector.collectedResults)
            }
            
            throw NoQueueForJobIdFoundError.noQueue(jobId: jobId)
        }
    }
}
