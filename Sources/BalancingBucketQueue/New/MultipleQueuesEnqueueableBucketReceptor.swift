import BucketQueue
import Foundation
import QueueModels

public final class MultipleQueuesEnqueueableBucketReceptor: EnqueueableBucketReceptor {
    private let bucketQueueFactory: BucketQueueFactory
    private let multipleQueuesContainer: MultipleQueuesContainer
    
    public init(
        bucketQueueFactory: BucketQueueFactory,
        multipleQueuesContainer: MultipleQueuesContainer
    ) {
        self.bucketQueueFactory = bucketQueueFactory
        self.multipleQueuesContainer = multipleQueuesContainer
    }
    
    public func enqueue(buckets: [Bucket], prioritizedJob: PrioritizedJob) throws {
        try multipleQueuesContainer.performWithExclusiveAccess {
            let bucketQueue: BucketQueue
            
            if let existingJobQueue = multipleQueuesContainer.runningJobQueues(jobId: prioritizedJob.jobId).first {
                bucketQueue = existingJobQueue.bucketQueue
            } else if let previouslyDeletedJobQueue = multipleQueuesContainer.allDeletedJobQueues().first(where: { $0.job.jobId == prioritizedJob.jobId }) {
                bucketQueue = previouslyDeletedJobQueue.bucketQueue
                bucketQueue.removeAllEnqueuedBuckets()
                
                multipleQueuesContainer.add(runningJobQueue: previouslyDeletedJobQueue)
                multipleQueuesContainer.removeFromDeleted(jobId: prioritizedJob.jobId)
            } else {
                bucketQueue = bucketQueueFactory.createBucketQueue()
                
                multipleQueuesContainer.add(
                    runningJobQueue: JobQueue(
                        bucketQueue: bucketQueue,
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
            try bucketQueue.enqueue(buckets: buckets)
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
