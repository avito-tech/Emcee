import BucketQueueModels
import Foundation
import EmceeLogging
import QueueModels
import TestHistoryTracker
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels


public final class SingleBucketQueueDequeueableBucketSource: DequeueableBucketSource {
    private let bucketQueueHolder: BucketQueueHolder
    private let logger: ContextualLogger
    private let testHistoryTracker: TestHistoryTracker
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    private let workerCapabilityConstraintResolver = WorkerCapabilityConstraintResolver()
    
    public init(
        bucketQueueHolder: BucketQueueHolder,
        logger: ContextualLogger,
        testHistoryTracker: TestHistoryTracker,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.bucketQueueHolder = bucketQueueHolder
        self.logger = logger.forType(Self.self)
        self.testHistoryTracker = testHistoryTracker
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }

    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        workerAlivenessProvider.willDequeueBucket(workerId: workerId)
        workerCapabilitiesStorage.set(workerCapabilities: workerCapabilities, forWorkerId: workerId)
        
        return bucketQueueHolder.performWithExclusiveAccess {
            let bucketToDequeueOrNil = testHistoryTracker.bucketToDequeue(
                workerId: workerId,
                queue: bucketQueueHolder.allEnqueuedBuckets,
                workerIdsInWorkingCondition: workerAlivenessProvider.workerIdsInWorkingCondition
            )
            
            if let enqueuedBucket = bucketToDequeueOrNil {
                guard workerCapabilityConstraintResolver.requirementsSatisfied(
                    requirements: enqueuedBucket.bucket.workerCapabilityRequirements,
                    workerCapabilities: workerCapabilities
                ) else {
                    logger.debug("capabilities \(workerCapabilities) of \(workerId) do not meet bucket requirements: \(enqueuedBucket.bucket.workerCapabilityRequirements)")
                    return nil
                }
                
                return dequeue(
                    enqueuedBucket: enqueuedBucket,
                    workerId: workerId
                )
            } else {
                return nil
            }
        }
    }
    
    private func dequeue(enqueuedBucket: EnqueuedBucket, workerId: WorkerId) -> DequeuedBucket {
        let dequeuedBucket = DequeuedBucket(enqueuedBucket: enqueuedBucket, workerId: workerId)
        
        bucketQueueHolder.replacePreviouslyEnqueuedBucket(withDequeuedBucket: dequeuedBucket)
        
        logger.debug("Dequeued new bucket: \(dequeuedBucket)")
        
        workerAlivenessProvider.didDequeueBucket(
            bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            workerId: workerId
        )
        
        return dequeuedBucket
    }
}
