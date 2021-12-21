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
        self.logger = logger
        self.testHistoryTracker = testHistoryTracker
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }

    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        workerAlivenessProvider.willDequeueBucket(workerId: workerId)
        workerCapabilitiesStorage.set(workerCapabilities: workerCapabilities, forWorkerId: workerId)
        
        return bucketQueueHolder.performWithExclusiveAccess {
            guard let enqueuedBucket = bucketQueueHolder.allEnqueuedBuckets.first else {
                return nil
            }
            
            switch enqueuedBucket.bucket.payload {
            case .runIosTests:
                return dequeueBucketWithTests(workerCapabilities: workerCapabilities, workerId: workerId)
            case .ping:
                return dequeue(enqueuedBucket: enqueuedBucket, workerId: workerId)
            }
        }
    }
    
    private func dequeueBucketWithTests(
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId
    ) -> DequeuedBucket? {
        let payloadToDequeueOrNil = testHistoryTracker.enqueuedPayloadToDequeue(
            workerId: workerId,
            queue: bucketQueueHolder.allEnqueuedBuckets.compactMap {
                switch $0.bucket.payload {
                case .runIosTests(let runIosTestsPayload):
                    return EnqueuedRunIosTestsPayload(
                        bucketId: $0.bucket.bucketId,
                        testDestination: runIosTestsPayload.testDestination,
                        testEntries: runIosTestsPayload.testEntries,
                        numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetries
                    )
                case .ping:
                    return nil
                }
            },
            workerIdsInWorkingCondition: workerAlivenessProvider.workerIdsInWorkingCondition
        )
        
        if let enqueuedPayload = payloadToDequeueOrNil, let enqueuedBucket = bucketQueueHolder.enqueuedBucket(bucketId: enqueuedPayload.bucketId) {
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
