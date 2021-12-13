import Dispatch
import EmceeExtensions
import Foundation
import EmceeLogging
import QueueCommunication
import QueueCommunicationModels
import QueueModels
import WorkerAlivenessModels

public final class WorkerAlivenessProviderImpl: WorkerAlivenessProvider {
    private let lock = NSLock()
    private let logger: ContextualLogger
    private var unsafe_registeredWorkerIds = Set<WorkerId>()
    private var unsafe_disabledWorkerIds = Set<WorkerId>()
    private var unsafe_silentWorkerIds = Set<WorkerId>()
    private let workerPermissionProvider: WorkerPermissionProvider
    private let workerBucketIdsBeingProcessed: WorkerCurrentlyProcessingBucketsTracker

    public init(
        logger: ContextualLogger,
        workerPermissionProvider: WorkerPermissionProvider
    ) {
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
        let previousMember = unsafe_silentWorkerIds.remove(workerId)
        if previousMember != nil {
            logger.debug("Marked \(workerId) as alive")
        }
    }
    
    private func unsafe_markWorkerAsSilent(workerId: WorkerId) {
        let result = unsafe_silentWorkerIds.insert(workerId)
        if result.inserted {
            logger.debug("Marked \(workerId) as silent")
        }
    }
    
    private func unsafe_workerAliveness() -> [WorkerId: WorkerAliveness] {
        var workerAliveness = [WorkerId: WorkerAliveness]()
        for id in unsafe_knownWorkerIds() {
            workerAliveness[id] = unsafe_alivenessForWorker(workerId: id)
        }
        return workerAliveness
    }
    
    private func unsafe_knownWorkerIds() -> Set<WorkerId> {
        var result = Set<WorkerId>()
        result.formUnion(unsafe_registeredWorkerIds)
        result.formUnion(unsafe_disabledWorkerIds)
        result.formUnion(unsafe_silentWorkerIds)
        return result
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
