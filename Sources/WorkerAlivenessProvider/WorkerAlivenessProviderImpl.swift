import DateProvider
import Dispatch
import Foundation
import Logging
import Models

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.workerAlivenessProvider.syncQueue")
    private let dateProvider: DateProvider
    /// a set of workers that are expected to have the aliveness statuses
    private let knownWorkerIds: Set<WorkerId>
    private var workerAliveReportTimestamps = [WorkerId: Date]()
    private let workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker()
    private var blockedWorkers = Set<WorkerId>()
    /// allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
    private let maximumNotReportingDuration: TimeInterval

    public init(
        dateProvider: DateProvider,
        knownWorkerIds: Set<WorkerId>,
        maximumNotReportingDuration: TimeInterval
    ) {
        self.dateProvider = dateProvider
        self.knownWorkerIds = knownWorkerIds
        self.maximumNotReportingDuration = maximumNotReportingDuration
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: WorkerId) {
        syncQueue.sync {
            onSyncQueue_markWorkerAsAlive(workerId: workerId)
            workerBucketIdsBeingProcessed.append(bucketId: bucketId, workerId: workerId)
        }
    }
    
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId) {
        syncQueue.sync {
            if !blockedWorkers.contains(workerId) {
                onSyncQueue_markWorkerAsAlive(workerId: workerId)
                workerBucketIdsBeingProcessed.set(bucketIdsBeingProcessed: bucketIdsBeingProcessed, byWorkerId: workerId)
            }
        }
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        syncQueue.sync {
           onSyncQueue_markWorkerAsAlive(workerId: workerId)
        }
    }
    
    public func blockWorker(workerId: WorkerId) {
        syncQueue.sync {
            _ = blockedWorkers.insert(workerId)
            workerBucketIdsBeingProcessed.resetBucketIdsBeingProcessedBy(workerId: workerId)
            Logger.warning("Blocked worker: \(workerId)")
            
            let workerAliveness = onSyncQueue_workerAliveness()
            Logger.debug("Alive workers: \(workerAliveness.filter { $0.value.status == .alive }), blocked workers: \(workerAliveness.filter { $0.value.status == .blocked })")
        }
    }
    
    public var workerAliveness: [WorkerId: WorkerAliveness] {
        return syncQueue.sync {
            onSyncQueue_workerAliveness()
        }
    }
    
    public func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        return syncQueue.sync {
            onSyncQueue_alivenessForWorker(workerId: workerId, currentDate: Date())
        }
    }
    
    private func onSyncQueue_workerAliveness() -> [WorkerId: WorkerAliveness] {
        let uniqueWorkerIds = Set<WorkerId>(workerAliveReportTimestamps.keys).union(blockedWorkers).union(knownWorkerIds)
        
        var workerAliveness = [WorkerId: WorkerAliveness]()
        let currentDate = Date()
        for id in uniqueWorkerIds {
            workerAliveness[id] = onSyncQueue_alivenessForWorker(workerId: id, currentDate: currentDate)
        }
        return workerAliveness
    }
    
    private func onSyncQueue_alivenessForWorker(workerId: WorkerId, currentDate: Date) -> WorkerAliveness {
        guard let latestAliveDate = workerAliveReportTimestamps[workerId] else {
            return WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
        }
        if blockedWorkers.contains(workerId) {
            return WorkerAliveness(status: .blocked, bucketIdsBeingProcessed: [])
        }
        
        let bucketIdsBeingProcessed = workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(workerId: workerId)
        let silenceDuration = currentDate.timeIntervalSince(latestAliveDate)
        if silenceDuration > maximumNotReportingDuration {
            return WorkerAliveness(status: .silent(lastAlivenessResponseTimestamp: latestAliveDate), bucketIdsBeingProcessed: bucketIdsBeingProcessed)
        } else {
            return WorkerAliveness(status: .alive, bucketIdsBeingProcessed: bucketIdsBeingProcessed)
        }
    }
    
    private func onSyncQueue_markWorkerAsAlive(workerId: WorkerId) {
        workerAliveReportTimestamps[workerId] = dateProvider.currentDate()
    }
}
