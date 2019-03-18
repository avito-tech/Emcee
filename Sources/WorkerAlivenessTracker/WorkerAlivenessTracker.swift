import Dispatch
import Foundation
import Logging

public final class WorkerAlivenessTracker: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.WorkerAlivenessTracker.syncQueue")
    private var workerAliveReportTimestamps = [String: Date]()
    private let workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker()
    private var blockedWorkers = Set<String>()
    /// allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
    private let maximumNotReportingDuration: TimeInterval

    public init(reportAliveInterval: TimeInterval, additionalTimeToPerformWorkerIsAliveReport: TimeInterval) {
        self.maximumNotReportingDuration = reportAliveInterval + additionalTimeToPerformWorkerIsAliveReport
    }
    
    public func markWorkerAsAlive(workerId: String) {
        syncQueue.sync {
            if !blockedWorkers.contains(workerId) {
                workerAliveReportTimestamps[workerId] = Date()
            }
        }
    }
    
    public func didDequeueBucket(bucketId: String, workerId: String) {
        syncQueue.sync {
            workerBucketIdsBeingProcessed.append(bucketId: bucketId, workerId: workerId)
        }
    }
    
    public func set(bucketIdsBeingProcessed: Set<String>, workerId: String) {
        syncQueue.sync {
            if !blockedWorkers.contains(workerId) {
                workerBucketIdsBeingProcessed.set(bucketIdsBeingProcessed: bucketIdsBeingProcessed, byWorkerId: workerId)
            }
        }
    }
    
    public func didRegisterWorker(workerId: String) {
        markWorkerAsAlive(workerId: workerId)
    }
    
    public func blockWorker(workerId: String) {
        syncQueue.sync {
            _ = blockedWorkers.insert(workerId)
            workerBucketIdsBeingProcessed.resetBucketIdsBeingProcessedBy(workerId: workerId)
            Logger.warning("Blocked worker: \(workerId)")
        }
    }
    
    public var workerAliveness: [String: WorkerAliveness] {
        return syncQueue.sync {
            let uniqueWorkerIds = Set<String>(workerAliveReportTimestamps.keys).union(blockedWorkers)
            
            var workerAliveness = [String: WorkerAliveness]()
            let currentDate = Date()
            for id in uniqueWorkerIds {
                workerAliveness[id] = onSyncQueue_alivenessForWorker(workerId: id, currentDate: currentDate)
            }
            return workerAliveness
        }
    }
    
    private func onSyncQueue_alivenessForWorker(workerId: String, currentDate: Date) -> WorkerAliveness {
        guard let latestAliveDate = workerAliveReportTimestamps[workerId] else {
            return WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
        }
        if blockedWorkers.contains(workerId) {
            return WorkerAliveness(status: .blocked, bucketIdsBeingProcessed: [])
        }
        
        let bucketIdsBeingProcessed = workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(workerId: workerId)
        let silenceDuration = Date().timeIntervalSince(latestAliveDate)
        if silenceDuration > maximumNotReportingDuration {
            return WorkerAliveness(status: .silent, bucketIdsBeingProcessed: bucketIdsBeingProcessed)
        } else {
            return WorkerAliveness(status: .alive, bucketIdsBeingProcessed: bucketIdsBeingProcessed)
        }
    }
}
