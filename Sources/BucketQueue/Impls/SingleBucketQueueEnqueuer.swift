import BucketQueueModels
import DateProvider
import Foundation
import QueueModels
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class SingleBucketQueueEnqueuer: BucketEnqueuer {
    private let bucketQueueHolder: BucketQueueHolder
    private let dateProvider: DateProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    private let workerCapabilityConstraintResolver = WorkerCapabilityConstraintResolver()
    
    public init(
        bucketQueueHolder: BucketQueueHolder,
        dateProvider: DateProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.bucketQueueHolder = bucketQueueHolder
        self.dateProvider = dateProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }
    
    public func enqueue(buckets: [Bucket]) throws {
        try validate(buckets: buckets)
        
        enqueueValidBuckets(buckets: buckets)
    }
    
    private func validate(buckets: [Bucket]) throws {
        struct BucketValidationError: Error, CustomStringConvertible {
            let buckets: [Bucket]
            
            var description: String {
                buckets.map {
                    "Bucket with \($0.bucketId) is not runnable because bucket requirements can't be met: \($0.workerCapabilityRequirements)"
                }.joined(separator: "; ")
            }
        }
        
        let allWorkerCapabilities = workerAlivenessProvider.workerAliveness
            .filter { $0.value.isInWorkingCondition }
            .map { workerCapabilitiesStorage.workerCapabilities(forWorkerId: $0.key) }

        let bucketsWithNotSatisifiedRequirements = buckets.filter { bucket -> Bool in
            !allWorkerCapabilities.contains { workerCapabilities in
                workerCapabilityConstraintResolver.requirementsSatisfied(
                    requirements: bucket.workerCapabilityRequirements,
                    workerCapabilities: workerCapabilities
                )
            }
        }
        if !bucketsWithNotSatisifiedRequirements.isEmpty {
            throw BucketValidationError(buckets: bucketsWithNotSatisifiedRequirements)
        }
    }
    
    private func enqueueValidBuckets(buckets: [Bucket]) {
        // For empty queue it just inserts buckets to the beginning,
        //
        // There is an optimization to insert additional (probably failed) buckets:
        //
        // If we insert new buckets to the end of the queue we will end up in a situation when
        // there will be a tail of failing tests at the end of the queue.
        //
        // If we insert it in at the beginning there will be a little delay between retries,
        // and, for example, some temporarily unavalable service in E2E won't stop failing yet.
        //
        // The ideal solution is to optimize the inserting position based on current queue,
        // current number of retries etc. For example, spread retires evenly throughout whole run.
        //
        // This is not optimal:
        //
        
        bucketQueueHolder.performWithExclusiveAccess {
            let positionJustAfterNextBucket = 1
            
            let positionLimit = bucketQueueHolder.allEnqueuedBuckets.count
            let positionToInsert = min(positionJustAfterNextBucket, positionLimit)
            let enqueuedBuckets = buckets.map {
                EnqueuedBucket(
                    bucket: $0,
                    enqueueTimestamp: dateProvider.currentDate(),
                    uniqueIdentifier: uniqueIdentifierGenerator.generate()
                )
            }
            bucketQueueHolder.insert(enqueuedBuckets: enqueuedBuckets, position: positionToInsert)
        }
    }
}
