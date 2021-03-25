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
    private var unsafe_registeredWorkerIds = Set<WorkerId>()
    private var unsafe_disabledWorkerIds = Set<WorkerId>()
    private var unsafe_silentWorkerIds = Set<WorkerId>()
    private let workerPermissionProvider: WorkerPermissionProvider
    private let workerBucketIdsBeingProcessed: WorkerCurrentlyProcessingBucketsTracker

    public init(
        knownWorkerIds: Set<WorkerId>,
        logger: ContextualLogger,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
        self.knownWorkerIds = knownWorkerIds
        self.logger = logger
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
            unsafe_registeredWorkerIds.contains(workerId)
        }
    }
    
    public func didRegisterWorker(workerId: WorkerId) {
        lock.whileLocked {
            unsafe_registeredWorkerIds.insert(workerId)
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
            unsafe_alivenessForWorker(workerId: workerId)
        }
    }
    
    public func enableWorker(workerId: WorkerId) {
        lock.whileLocked {
            if unsafe_disabledWorkerIds.contains(workerId) {
                logger.debug("Enabling \(workerId)")
                _ = unsafe_disabledWorkerIds.remove(workerId)
            }
        }
    }
    
    public func disableWorker(workerId: WorkerId) {
        lock.whileLocked {
            if !unsafe_disabledWorkerIds.contains(workerId) {
                logger.debug("Disabling \(workerId)")
                _ = unsafe_disabledWorkerIds.insert(workerId)
            }
        }
    }
    
    public func isWorkerEnabled(workerId: WorkerId) -> Bool {
        lock.whileLocked {
            !unsafe_disabledWorkerIds.contains(workerId)
        }
    }
    
    public func setWorkerIsSilent(workerId: WorkerId) {
        lock.whileLocked {
            unsafe_markWorkerAsSilent(workerId: workerId)
        }
    }
    
    public func isWorkerSilent(workerId: WorkerId) -> Bool {
        lock.whileLocked {
            unsafe_silentWorkerIds.contains(workerId)
        }
    }
    
    private func unsafe_markWorkerAsAlive(workerId: WorkerId) {
        if unsafe_silentWorkerIds.contains(workerId) {
            logger.debug("Marking \(workerId) as alive")
            _ = unsafe_silentWorkerIds.remove(workerId)
        }
    }
    
    private func unsafe_markWorkerAsSilent(workerId: WorkerId) {
        if !unsafe_silentWorkerIds.contains(workerId) {
            logger.debug("Marking \(workerId) as silent")
            _ = unsafe_silentWorkerIds.insert(workerId)
        }
    }
    
    private func unsafe_workerAliveness() -> [WorkerId: WorkerAliveness] {
        var workerAliveness = [WorkerId: WorkerAliveness](minimumCapacity: knownWorkerIds.count)
        for id in knownWorkerIds {
            workerAliveness[id] = unsafe_alivenessForWorker(workerId: id)
        }
        return workerAliveness
    }
    
    private func unsafe_alivenessForWorker(workerId: WorkerId) -> WorkerAliveness {
        WorkerAliveness(
            registered: unsafe_registeredWorkerIds.contains(workerId),
            bucketIdsBeingProcessed: workerBucketIdsBeingProcessed.bucketIdsBeingProcessedBy(
                workerId: workerId
            ),
            disabled: unsafe_disabledWorkerIds.contains(workerId),
            silent: unsafe_silentWorkerIds.contains(workerId),
            workerUtilizationPermission: workerPermissionProvider.utilizationPermissionForWorker(
                workerId: workerId
            )
        )
    }
}
