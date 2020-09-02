import Dispatch
import Foundation
import Logging
import QueueCommunication
import QueueCommunicationModels
import QueueModels
import WorkerAlivenessModels

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.workerAlivenessProvider.syncQueue")
    private let knownWorkerIds: Set<WorkerId>
    private var registeredWorkerIds = Set<WorkerId>()
    private var disabledWorkerIds = Set<WorkerId>()
    private var silentWorkerIds = Set<WorkerId>()
    private let workerPermissionProvider: WorkerPermissionProvider
    private let workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker()

    public init(
        knownWorkerIds: Set<WorkerId>,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
        self.knownWorkerIds = knownWorkerIds
        self.workerPermissionProvider = workerPermissionProvider
    }
    
    public func willDequeueBucket(workerId: WorkerId) {
        syncQueue.sync {
            onSyncQueue_markWorkerAsAlive(workerId: workerId)
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
    
    public func bucketIdsBeingProcessed(workerId: WorkerId) -> Set<BucketId> {
        syncQueue.sync {
            workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(workerId: workerId)
        }
    }
    
    public func isWorkerRegistered(workerId: WorkerId) -> Bool {
        syncQueue.sync {
            registeredWorkerIds.contains(workerId)
        }
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        syncQueue.sync {
            registeredWorkerIds.insert(workerId)
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
    
    public func isWorkerEnabled(workerId: WorkerId) -> Bool {
        syncQueue.sync {
            !disabledWorkerIds.contains(workerId)
        }
    }
    
    public func setWorkerIsSilent(workerId: WorkerId) {
        syncQueue.sync {
            onSyncQueue_markWorkerAsSilent(workerId: workerId)
        }
    }
    
    public func isWorkerSilent(workerId: WorkerId) -> Bool {
        syncQueue.sync {
            silentWorkerIds.contains(workerId)
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
        WorkerAliveness(
            registered: registeredWorkerIds.contains(workerId),
            bucketIdsBeingProcessed: workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(
                workerId: workerId
            ),
            disabled: disabledWorkerIds.contains(workerId),
            silent: silentWorkerIds.contains(workerId),
            workerUtilizationPermission: workerPermissionProvider.utilizationPermissionForWorker(
                workerId: workerId
            )
        )
    }
}
