import CountedSet
import EmceeExtensions
import Foundation
import QueueModels

public final class MultipleQueuesContainer {
    private let discreteAccessLock = NSLock()
    private let continousAccessLock = NSLock()

    public init() {}
    
    public func performWithExclusiveAccess<T>(
        work: () throws -> T
    ) rethrows -> T {
        try continousAccessLock.whileLocked(work)
    }
    
    public func runningAndDeletedJobQueues() -> [JobQueue] {
        discreteAccessLock.whileLocked {
            unsafe_runningJobQueues + unsafe_deletedJobQueues
        }
    }
    
    // MARK: - JobGroups
    
    private var unsafe_runningJobGroups = CountedSet<JobGroup>()
    
    public func track(jobGroup: JobGroup) {
        discreteAccessLock.whileLocked {
            _ = unsafe_runningJobGroups.update(with: jobGroup)
        }
    }
    
    public func untrack(jobGroup: JobGroup) {
        discreteAccessLock.whileLocked {
            _ = unsafe_runningJobGroups.remove(jobGroup)
        }
    }
    
    public func trackedJobGroups() -> [JobGroup] {
        discreteAccessLock.whileLocked {
            Array(unsafe_runningJobGroups)
        }
    }
    
    // MARK: - Running Job Queues
    
    private var unsafe_runningJobQueues = [JobQueue]()
    
    public func runningJobQueues(jobId: JobId) -> [JobQueue] {
        discreteAccessLock.whileLocked {
            unsafe_runningJobQueues.filter { $0.job.jobId == jobId }
        }
    }
    
    public func add(runningJobQueue: JobQueue) {
        discreteAccessLock.whileLocked {
            unsafe_runningJobQueues.append(runningJobQueue)
            unsafe_runningJobQueues.sort { $0.executionOrder(relativeTo: $1) == .before }
        }
    }
    
    public func removeRunningJobQueues(jobId: JobId) {
        discreteAccessLock.whileLocked {
            unsafe_runningJobQueues.removeAll(where: { $0.job.jobId == jobId })
        }
    }
    
    public func allRunningJobQueues() -> [JobQueue] {
        discreteAccessLock.whileLocked {
            unsafe_runningJobQueues
        }
    }
    
    // MARK: - Deleted Job Queues
    
    private var unsafe_deletedJobQueues = [JobQueue]()
    
    public func add(deletedJobQueues: [JobQueue]) {
        discreteAccessLock.whileLocked {
            unsafe_deletedJobQueues.append(contentsOf: deletedJobQueues)
        }
    }
    
    public func allDeletedJobQueues() -> [JobQueue] {
        discreteAccessLock.whileLocked {
            unsafe_deletedJobQueues
        }
    }
    
    public func removeFromDeleted(jobId: JobId) {
        discreteAccessLock.whileLocked {
            unsafe_deletedJobQueues.removeAll(where: { $0.job.jobId == jobId })
        }
    }
}
