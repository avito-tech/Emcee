import BucketQueueModels
import Foundation
import Logging
import QueueModels
import UniqueIdentifierGenerator
import WorkerAlivenessProvider


public final class SingleBucketQueueStuckBucketsReenqueuer: StuckBucketsReenqueuer {
    private let bucketEnqueuer: BucketEnqueuer
    private let bucketQueueHolder: BucketQueueHolder
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        bucketEnqueuer: BucketEnqueuer,
        bucketQueueHolder: BucketQueueHolder,
        workerAlivenessProvider: WorkerAlivenessProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.bucketEnqueuer = bucketEnqueuer
        self.bucketQueueHolder = bucketQueueHolder
        self.workerAlivenessProvider = workerAlivenessProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func reenqueueStuckBuckets() -> [StuckBucket] {
        bucketQueueHolder.performWithExclusiveAccess {
            let allDequeuedBuckets = bucketQueueHolder.allDequeuedBuckets
            let stuckBuckets: [StuckBucket] = allDequeuedBuckets.compactMap { dequeuedBucket in
                let aliveness = workerAlivenessProvider.alivenessForWorker(workerId: dequeuedBucket.workerId)

                let stuckReason: StuckBucket.Reason
                if aliveness.isInWorkingCondition {
                    if aliveness.bucketIdsBeingProcessed.contains(dequeuedBucket.enqueuedBucket.bucket.bucketId) {
                       return nil
                    }
                    stuckReason = .bucketLost
                } else if aliveness.silent {
                    stuckReason = .workerIsSilent
                } else {
                    return nil
                }
                
                bucketQueueHolder.remove(dequeuedBucket: dequeuedBucket)
                return StuckBucket(
                    reason: stuckReason,
                    bucket: dequeuedBucket.enqueuedBucket.bucket,
                    workerId: dequeuedBucket.workerId
                )
            }
            
            // Every stucked test produces a single bucket with itself
            let buckets = stuckBuckets.flatMap { stuckBucket in
                stuckBucket.bucket.testEntries.map { testEntry in
                    Bucket(
                        bucketId: BucketId(value: uniqueIdentifierGenerator.generate()),
                        buildArtifacts: stuckBucket.bucket.buildArtifacts,
                        developerDir: stuckBucket.bucket.developerDir,
                        pluginLocations: stuckBucket.bucket.pluginLocations,
                        simulatorControlTool: stuckBucket.bucket.simulatorControlTool,
                        simulatorOperationTimeouts: stuckBucket.bucket.simulatorOperationTimeouts,
                        simulatorSettings: stuckBucket.bucket.simulatorSettings,
                        testDestination: stuckBucket.bucket.testDestination,
                        testEntries: [testEntry],
                        testExecutionBehavior: stuckBucket.bucket.testExecutionBehavior,
                        testRunnerTool: stuckBucket.bucket.testRunnerTool,
                        testTimeoutConfiguration: stuckBucket.bucket.testTimeoutConfiguration,
                        testType: stuckBucket.bucket.testType,
                        workerCapabilityRequirements: stuckBucket.bucket.workerCapabilityRequirements,
                        persistentMetricsJobId: stuckBucket.bucket.persistentMetricsJobId
                    )
                }
            }
            
            if !buckets.isEmpty {
                Logger.debug("Got \(stuckBuckets.count) stuck buckets")
                do {
                    try bucketEnqueuer.enqueue(buckets: buckets)
                    Logger.debug("Reenqueued \(stuckBuckets.count) stuck buckets as \(buckets.count) new buckets:")
                    for bucket in buckets {
                        Logger.debug("-- \(bucket.bucketId)")
                    }
                } catch {
                    Logger.error("Failed to reenqueue \(stuckBuckets.count) buckets: \(error)")
                }
            }
            
            return stuckBuckets
        }
    }
}
