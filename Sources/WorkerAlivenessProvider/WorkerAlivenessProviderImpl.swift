import Dispatch
import Foundation
import Logging
import Models

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private enum InternalStatus {
        case notRegistered
        case registered
    }
    
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.workerAlivenessProvider.syncQueue")
    private let knownWorkerIds: Set<WorkerId>
    private var workerStatuses = [WorkerId: InternalStatus]()
    private var disabledWorkerIds = Set<WorkerId>()
    private var silentWorkerIds = Set<WorkerId>()
    private let workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker()

    public init(
        knownWorkerIds: Set<WorkerId>
    ) {
        self.knownWorkerIds = knownWorkerIds
        for workerId in knownWorkerIds {
            workerStatuses[workerId] = .notRegistered
        }
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
            workerStatuses[workerId] = .registered
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
            onSyncQueue_alivenessForWorker(workerId: workerId)
        }
    }
    
    public func enableWorker(workerId: WorkerId) {
        syncQueue.sync {
            if disabledWorkerIds.contains(workerId) {
                Logger.debug("Enabling \(workerId)")
                _ = disabledWorkerIds.remove(workerId)
            }
        }
    }
    
    public func disableWorker(workerId: WorkerId) {
        syncQueue.sync {
            if !disabledWorkerIds.contains(workerId) {
                Logger.debug("Disabling \(workerId)")
                _ = disabledWorkerIds.insert(workerId)
            }
        }
    }
    
    public func setWorkerIsSilent(workerId: WorkerId) {
        syncQueue.sync {
            onSyncQueue_markWorkerAsSilent(workerId: workerId)
        }
    }
    
    private func onSyncQueue_markWorkerAsAlive(workerId: WorkerId) {
        if silentWorkerIds.contains(workerId) {
            Logger.debug("Marking \(workerId) as alive")
            _ = silentWorkerIds.remove(workerId)
        }
    }
    
    private func onSyncQueue_markWorkerAsSilent(workerId: WorkerId) {
        if !silentWorkerIds.contains(workerId) {
            Logger.debug("Marking \(workerId) as silent")
            _ = silentWorkerIds.insert(workerId)
        }
    }
    
    private func onSyncQueue_workerAliveness() -> [WorkerId: WorkerAliveness] {
        var workerAliveness = [WorkerId: WorkerAliveness]()
        for id in knownWorkerIds {
            workerAliveness[id] = onSyncQueue_alivenessForWorker(workerId: id)
        }
        return workerAliveness
    }
    
    private func onSyncQueue_alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        guard let internalStatus = workerStatuses[workerId] else {
            return WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
        }
        
        switch internalStatus {
        case .notRegistered:
            return WorkerAliveness(
                status: .notRegistered,
                bucketIdsBeingProcessed: []
            )
        case .registered:
            let bucketIdsBeingProcessed = workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(
                workerId: workerId
            )
            
            if disabledWorkerIds.contains(workerId) {
                return WorkerAliveness(
                    status: .disabled,
                    bucketIdsBeingProcessed: bucketIdsBeingProcessed)
            } else if silentWorkerIds.contains(workerId) {
                return WorkerAliveness(
                    status: .silent,
                    bucketIdsBeingProcessed: bucketIdsBeingProcessed
                )
            } else {
                return WorkerAliveness(
                    status: .alive,
                    bucketIdsBeingProcessed: bucketIdsBeingProcessed
                )
            }
        }
    }
}
