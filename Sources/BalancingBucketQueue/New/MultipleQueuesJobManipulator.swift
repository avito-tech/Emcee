import DateProvider
import Foundation
import QueueModels
import Metrics
import LocalHostDeterminer

public final class MultipleQueuesJobManipulator: JobManipulator {
    private let dateProvider: DateProvider
    private let multipleQueuesContainer: MultipleQueuesContainer
    private let emceeVersion: Version
    
    public init(
        dateProvider: DateProvider,
        multipleQueuesContainer: MultipleQueuesContainer,
        emceeVersion: Version
    ) {
        self.dateProvider = dateProvider
        self.multipleQueuesContainer = multipleQueuesContainer
        self.emceeVersion = emceeVersion
    }
    
    public func delete(jobId: JobId) throws {
        try multipleQueuesContainer.performWithExclusiveAccess {
            let jobQueuesToDelete = multipleQueuesContainer.runningJobQueues(jobId: jobId)
            guard !jobQueuesToDelete.isEmpty else {
                throw NoQueueForJobIdFoundError.noQueue(jobId: jobId)
            }
            for jobQueue in jobQueuesToDelete {
                jobQueue.bucketQueue.removeAllEnqueuedBuckets()
            }
            
            multipleQueuesContainer.add(deletedJobQueues: jobQueuesToDelete)
            multipleQueuesContainer.removeRunningJobQueues(jobId: jobId)
            
            for deletedJobQueue in jobQueuesToDelete {
                multipleQueuesContainer.untrack(jobGroup: deletedJobQueue.jobGroup)
            
                MetricRecorder.capture(
                    JobProcessingDurationMetric(
                        queueHost: LocalHostDeterminer.currentHostAddress,
                        version: emceeVersion,
                        persistentMetricsJobId: deletedJobQueue.persistentMetricsJobId,
                        duration: dateProvider.currentDate().timeIntervalSince(deletedJobQueue.job.creationTime)
                    )
                )
            }
        }
    }
}
