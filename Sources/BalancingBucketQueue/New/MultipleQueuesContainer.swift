import CountedSet
import Foundation
import QueueModels

public final class MultipleQueuesContainer {
    private let syncQueue = DispatchQueue(label: "MultipleQueuesContainer.syncQueue")
    private let exclusiveAccessLock = NSLock()

    public init() {}
    
    public func performWithExclusiveAccess<T>(
        work: () throws -> T
    ) rethrows -> T {
        exclusiveAccessLock.lock()
        defer {
            exclusiveAccessLock.unlock()
        }
        return try work()
    }
    
    public func runningAndDeletedJobQueues() -> [JobQueue] {
        syncQueue.sync {
            runningJobQueues_onSyncQueue + deletedJobQueues_onSyncQueue
        }
    }
    
    // MARK: - JobGroups
    
    private var runningJobGroups_onSyncQueue = CountedSet<JobGroup>()
    
    public func track(jobGroup: JobGroup) {
        syncQueue.sync {
            _ = runningJobGroups_onSyncQueue.update(with: jobGroup)
        }
    }
    
    public func untrack(jobGroup: JobGroup) {
        syncQueue.sync {
            _ = runningJobGroups_onSyncQueue.remove(jobGroup)
        }
    }
    
    public func trackedJobGroups() -> [JobGroup] {
        syncQueue.sync {
            Array(runningJobGroups_onSyncQueue)
        }
    }
    
    // MARK: - Running Job Queues
    
    private var runningJobQueues_onSyncQueue = [JobQueue]()
    
    public func runningJobQueues(jobId: JobId) -> [JobQueue] {
        syncQueue.sync {
            runningJobQueues_onSyncQueue.filter { $0.job.jobId == jobId }
        }
    }
    
    public func add(runningJobQueue: JobQueue) {
        syncQueue.sync {
            runningJobQueues_onSyncQueue.append(runningJobQueue)
            runningJobQueues_onSyncQueue.sort { $0.executionOrder(relativeTo: $1) == .before }
        }
    }
    
    public func removeRunningJobQueues(jobId: JobId) {
        syncQueue.sync {
            runningJobQueues_onSyncQueue.removeAll(where: { $0.job.jobId == jobId })
        }
    }
    
    public func allRunningJobQueues() -> [JobQueue] {
        syncQueue.sync {
            runningJobQueues_onSyncQueue
        }
    }
    
    // MARK: - Deleted Job Queues
    
    private var deletedJobQueues_onSyncQueue = [JobQueue]()
    
    public func add(deletedJobQueues: [JobQueue]) {
        syncQueue.sync {
            deletedJobQueues_onSyncQueue.append(contentsOf: deletedJobQueues)
        }
    }
    
    public func allDeletedJobQueues() -> [JobQueue] {
        syncQueue.sync {
            deletedJobQueues_onSyncQueue
        }
    }
    
    public func removeFromDeleted(jobId: JobId) {
        syncQueue.sync {
            deletedJobQueues_onSyncQueue.removeAll(where: { $0.job.jobId == jobId })
        }
    }
}
