import Dispatch
import Extensions
import Foundation
import EmceeLogging
import QueueCommunication
import QueueCommunicationModels
import QueueModels
import WorkerAlivenessModels

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private let lock = NSLock()
    private let knownWorkerIds: Set<WorkerId>
    private let logger: ContextualLogger
    private var registeredWorkerIds = Set<WorkerId>()
    private var disabledWorkerIds = Set<WorkerId>()
    private var silentWorkerIds = Set<WorkerId>()
    private let workerPermissionProvider: WorkerPermissionProvider
    private let workerBucketIdsBeingProcessed: WorkerCurrentlyProcessingBucketsTracker

    public init(
        knownWorkerIds: Set<WorkerId>,
        logger: ContextualLogger,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
        self.knownWorkerIds = knownWorkerIds
        self.logger = logger.forType(Self.self)
        self.workerPermissionProvider = workerPermissionProvider
        self.workerBucketIdsBeingProcessed = WorkerCurrentlyProcessingBucketsTracker(logger: logger)
    }
    
    public func willDequeueBucket(workerId: WorkerId) {
        lock.whileLocked {
            unsafe_markWorkerAsAlive(workerId: workerId)
        }
    }
    
    public func didDequeueBucket(bucketId: BucketId, workerId: WorkerId) {
        lock.whileLocked {
            unsafe_markWorkerAsAlive(workerId: workerId)
            workerBucketIdsBeingProcessed.append(bucketId: bucketId, workerId: workerId)
        }
    }
    
    public func set(bucketIdsBeingProcessed: Set<BucketId>, workerId: WorkerId) {
        lock.whileLocked {
            unsafe_markWorkerAsAlive(workerId: workerId)
            workerBucketIdsBeingProcessed.set(bucketIdsBeingProcessed: bucketIdsBeingProcessed, byWorkerId: workerId)
        }
    }
    
    public func bucketIdsBeingProcessed(workerId: WorkerId) -> Set<BucketId> {
        lock.whileLocked {
            workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(workerId: workerId)
        }
    }
    
    public func isWorkerRegistered(workerId: WorkerId) -> Bool {
        lock.whileLocked {
            registeredWorkerIds.contains(workerId)
        }
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        lock.whileLocked {
            registeredWorkerIds.insert(workerId)
            unsafe_markWorkerAsAlive(workerId: workerId)
        }
    }
        
    public var workerAliveness: [WorkerId: WorkerAliveness] {
        lock.whileLocked {
            unsafe_workerAliveness()
        }
    }
    
    public func alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        lock.whileLocked {
            onSyncQueue_alivenessForWorker(workerId: workerId)
        }
    }
    
    public func enableWorker(workerId: WorkerId) {
        lock.whileLocked {
            if disabledWorkerIds.contains(workerId) {
                logger.debug("Enabling \(workerId)")
                _ = disabledWorkerIds.remove(workerId)
            }
        }
    }
    
    public func disableWorker(workerId: WorkerId) {
        lock.whileLocked {
            if !disabledWorkerIds.contains(workerId) {
                logger.debug("Disabling \(workerId)")
                _ = disabledWorkerIds.insert(workerId)
            }
        }
    }
    
    public func isWorkerEnabled(workerId: WorkerId) -> Bool {
        lock.whileLocked {
            !disabledWorkerIds.contains(workerId)
        }
    }
    
    public func setWorkerIsSilent(workerId: WorkerId) {
        lock.whileLocked {
            unsafe_markWorkerAsSilent(workerId: workerId)
        }
    }
    
    public func isWorkerSilent(workerId: WorkerId) -> Bool {
        lock.whileLocked {
            silentWorkerIds.contains(workerId)
        }
    }
    
    private func unsafe_markWorkerAsAlive(workerId: WorkerId) {
        if silentWorkerIds.contains(workerId) {
            logger.debug("Marking \(workerId) as alive")
            _ = silentWorkerIds.remove(workerId)
        }
    }
    
    private func unsafe_markWorkerAsSilent(workerId: WorkerId) {
        if !silentWorkerIds.contains(workerId) {
            logger.debug("Marking \(workerId) as silent")
            _ = silentWorkerIds.insert(workerId)
        }
    }
    
    private func unsafe_workerAliveness() -> [WorkerId: WorkerAliveness] {
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
