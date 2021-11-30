import BucketQueue
import Foundation
import QueueModels

public final class MultipleQueuesEnqueueableBucketReceptor: EnqueueableBucketReceptor {
    private let bucketEnqueuerProvider: BucketEnqueuerProvider
    private let emptyableBucketQueueProvider: EmptyableBucketQueueProvider
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(
        bucketEnqueuerProvider: BucketEnqueuerProvider,
        emptyableBucketQueueProvider: EmptyableBucketQueueProvider,
        multipleQueuesContainer: MultipleQueuesContainer
    ) {
        self.bucketEnqueuerProvider = bucketEnqueuerProvider
        self.emptyableBucketQueueProvider = emptyableBucketQueueProvider
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) throws {
        try multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueueHolder: BucketQueueHolder
            
            if let existingJobQueue = multipleQueuesContainer.runningJobQueues(jobId: prioritizedJob.jobId).first {
                bucketQueueHolder = existingJobQueue.bucketQueueHolder
            } else if let previouslyDeletedJobQueue = multipleQueuesContainer.allDeletedJobQueues().first(where: { $0.job.jobId == prioritizedJob.jobId }) {
                bucketQueueHolder = previouslyDeletedJobQueue.bucketQueueHolder
                
                emptyableBucketQueueProvider.createEmptyableBucketQueue(
                    bucketQueueHolder: bucketQueueHolder
                ).removeAllEnqueuedBuckets()
                
                multipleQueuesContainer.add(runningJobQueue: previouslyDeletedJobQueue)
                multipleQueuesContainer.removeFromDeleted(jobId: prioritizedJob.jobId)
            } else {
                bucketQueueHolder = BucketQueueHolder()
                
                multipleQueuesContainer.add(
                    runningJobQueue: JobQueue(
                        analyticsConfiguration: prioritizedJob.analyticsConfiguration,
                        bucketQueueHolder: bucketQueueHolder,
                        job: Job(creationTime: Date(), jobId: prioritizedJob.jobId, priority: prioritizedJob.jobPriority),
                        jobGroup: fetchOrCreateJobGroup(
                            jobGroupId: prioritizedJob.jobGroupId,
                            jobGroupPriority: prioritizedJob.jobGroupPriority
                        ),
                        resultsCollector: ResultsCollector()
                    )
                )
                multipleQueuesContainer.removeFromDeleted(jobId: prioritizedJob.jobId)
            }
            
            try bucketEnqueuerProvider.createBucketEnqueuer(
                bucketQueueHolder: bucketQueueHolder
            ).enqueue(buckets: buckets)
        }
    }
    
    private func fetchOrCreateJobGroup(
        jobGroupId: JobGroupId,
        jobGroupPriority: Priority
    ) -> JobGroup {
        let matchingJobGroups = multipleQueuesContainer.trackedJobGroups().filter {
            $0.jobGroupId == jobGroupId && $0.priority == jobGroupPriority
        }
        
        let jobGroup: JobGroup
        
        if let matchingJobGroup = matchingJobGroups.first {
            jobGroup = matchingJobGroup
        } else {
            jobGroup = JobGroup(
                creationTime: Date(),
                jobGroupId: jobGroupId,
                priority: jobGroupPriority
            )
        }
        
        multipleQueuesContainer.track(jobGroup: jobGroup)
        
        return jobGroup
    }
}
