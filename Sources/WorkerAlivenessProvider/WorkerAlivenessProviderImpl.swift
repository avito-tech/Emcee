import DateProvider
import Dispatch
import Foundation
import Logging
import Models

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.workerAlivenessProvider.syncQueue")
    private let dateProvider: DateProvider
    private let knownWorkerIds: Set<WorkerId>
    private var disabledWorkerIds = Set<WorkerId>()
    private var workerAliveReportTimestamps = [WorkerId: Date]()
    private let workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker()
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
            onSyncQueue_markWorkerAsAlive(workerId: workerId)
            workerBucketIdsBeingProcessed.set(bucketIdsBeingProcessed: bucketIdsBeingProcessed, byWorkerId: workerId)
        }
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        syncQueue.sync {
           onSyncQueue_markWorkerAsAlive(workerId: workerId)
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
    
    public func enableWorker(workerId: WorkerId) {
        syncQueue.sync {
            _ = disabledWorkerIds.remove(workerId)
        }
    }
    
    public func disableWorker(workerId: WorkerId) {
        syncQueue.sync {
            _ = disabledWorkerIds.insert(workerId)
        }
    }
    
    private func onSyncQueue_workerAliveness() -> [WorkerId: WorkerAliveness] {
        let uniqueWorkerIds = Set<WorkerId>(workerAliveReportTimestamps.keys).union(knownWorkerIds)
        
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
        
        let bucketIdsBeingProcessed = workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(workerId: workerId)
        let silenceDuration = currentDate.timeIntervalSince(latestAliveDate)
        if silenceDuration > maximumNotReportingDuration {
            return WorkerAliveness(
                status: .silent(lastAlivenessResponseTimestamp: latestAliveDate),
                bucketIdsBeingProcessed: bucketIdsBeingProcessed
            )
        } else if disabledWorkerIds.contains(workerId) {
            return WorkerAliveness(
                status: .disabled,
                bucketIdsBeingProcessed: bucketIdsBeingProcessed)
        } else {
            return WorkerAliveness(
                status: .alive,
                bucketIdsBeingProcessed: bucketIdsBeingProcessed
            )
        }
    }
    
    private func onSyncQueue_markWorkerAsAlive(workerId: WorkerId) {
        workerAliveReportTimestamps[workerId] = dateProvider.currentDate()
    }
}
